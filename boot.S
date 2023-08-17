.section ".text.boot"

.global _start

_start:	// each individual core will execute code upon startup
	mrs	x1, mpidr_el1	// read the multiprocesor affinity register to get the core ID
	and	x1, x1, #3	// make the core ID to keep only the lower two bits
	cbz	x1, 2f		// if core ID is zero, goto label 2 (main core), else continue to label 1

1:	// not on the main core... if the core that is executing the code is not the main core it will stay in this loop
	wfe			// wait for an event(halt the core temporarily)
	b	1b		// branch to label 1, infinite loop to wait

2:	// on the main core
	ldr	x1, =_start	// load the address of _start into register x1
	mov	sp, x1		// set the stack pointer to the value in x1 (address of _start)

	// clean the BSS section
	ldr	x1, =__bss_start	// load the address of the BSS section start into register x1
	ldr 	w2, =__bs_size		// load the size of the BSS section into register w2

3:	// compare and branch on zero
	cbz	w2, 4f			// if size is zero, exit the loop, else continue to label 4
	// xzr = 64 bit zero
	str	xzr, [x1], #8		// store zero into the memory address pointed by x1 (clearing BSS)
	sub	w2, w2, #1		// decrement the size of BSS by 1 (8 bytes at a time)
	// compare and branch on non-zero
	cbnz	w2, 3b			// if size is still non-zero branch to label 3 and repeat loop

4:	// jump to our main() routine in C and make sure it doesn't return
	bl	main		// branch with link to the main() routine in C (call function)
	// address of main is stored in the link register
	// in case it does return, halt the master core too
	b	1b		// if main() returns, loop and halt the core
