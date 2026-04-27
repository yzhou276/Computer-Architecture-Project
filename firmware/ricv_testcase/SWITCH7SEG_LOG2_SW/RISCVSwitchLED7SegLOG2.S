#define GPIO_SWs    0xbf800004
#define GPIO_LEDs   0xbf800000

.globl _start
_start:

main_loop:
    # Load switch GPIO address
    li   a1, GPIO_SWs

    # Read switch value into a0
    lw   a0, 0(a1)

    # Call software ceil(log2) routine
    jal  ra, soft_log2_ceil

    # Load LED GPIO address
    li   a1, GPIO_LEDs

    # Write result to LEDs
    sw   a0, 0(a1)

    # Repeat forever
    jal  zero, main_loop


soft_log2_ceil:
    # Load constant 1
    li   t0, 1

    # If n <= 1, return 0
    bleu a0, t0, log2_done_zero

    # Use n - 1 so result becomes ceil(log2(n))
    addi t1, a0, -1

    # count = 0
    li   t2, 0

log2_loop:
    # Shift right by 1, same as unsigned divide by 2
    srli t1, t1, 1

    # count++
    addi t2, t2, 1

    # Continue until shifted value becomes 0
    bnez t1, log2_loop

    # Return count
    mv   a0, t2

    # Return to caller
    ret

log2_done_zero:
    # Return 0 for n = 0 or n = 1
    li   a0, 0

    # Return to caller
    ret