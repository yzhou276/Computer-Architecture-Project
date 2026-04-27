#define GPIO_SWs    0xbf800004
#define GPIO_LEDs   0xbf800000

.globl _start
_start:

main_loop:
    # Load switch GPIO address
    li   a1, GPIO_SWs
    # Read switch value into a0
    lw   a0, 0(a1)
    # Call non-restoring integer sqrt routine
    jal  ra, soft_sqrt_nonrestoring
    # Load LED GPIO address
    li   a1, GPIO_LEDs
    # Write sqrt result to LEDs
    sw   a0, 0(a1)
    # Repeat forever
    jal  zero, main_loop

soft_sqrt_nonrestoring:
    # Copy input radicand into t0
    mv   t0, a0
    # Initialize root Q = 0
    li   t1, 0
    # Initialize signed remainder R = 0
    li   t2, 0
    # A 32-bit input has 16 groups of 2 bits
    li   t3, 16

sqrt_loop:
    # Extract the next top two bits of the radicand
    srli t4, t0, 30
    # Shift radicand left by 2 for the next iteration
    slli t0, t0, 2
    # If remainder is negative, use the add-back path
    bltz t2, sqrt_rem_negative
    # nop
    # nop
    # nop
    # nop
    # nop
    # nop
    # nop
    # nop

sqrt_rem_positive:
    # Shift remainder left by 2
    slli t2, t2, 2
    # Bring down the next two input bits
    or   t2, t2, t4
    # Compute trial value = (Q << 2) | 1
    slli t5, t1, 2
    # Add low bit to trial value
    ori  t5, t5, 1
    # R = R - trial
    sub  t2, t2, t5
    # Go update root
    jal  zero, sqrt_update_root

sqrt_rem_negative:
    # Shift remainder left by 2
    slli t2, t2, 2
    # Bring down the next two input bits
    or   t2, t2, t4
    # Compute trial value = (Q << 2) | 3
    slli t5, t1, 2
    # Add correction bits to trial value
    ori  t5, t5, 3
    # R = R + trial
    add  t2, t2, t5

sqrt_update_root:
    # nop
    # nop
    # Shift root left by 1
    slli t1, t1, 1
    # nop
    # nop
    # If remainder is negative, next root bit is 0
    bltz t2, sqrt_next_iter
    # nop
    # nop
    # If remainder is non-negative, next root bit is 1
    ori  t1, t1, 1

sqrt_next_iter:
    # Decrement loop counter
    addi t3, t3, -1
    # Continue until all 16 two-bit groups are processed
    bnez t3, sqrt_loop
    # Move final root into return register
    mv   a0, t1
    # Return to caller
    ret