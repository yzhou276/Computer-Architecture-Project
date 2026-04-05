module isqrt32_nonrestoring (
    input  logic         clk,
    input  logic         rst_n,
    input  logic         start,     // Pulse high for one cycle to start a new sqrt operation
    input  logic [31:0]  radicand,  // 32-bit unsigned input operand
    output logic         busy,      // High while the iterative algorithm is running
    output logic         done,      // Pulses high for one cycle when result is ready
    output logic [15:0]  root,      // floor(sqrt(radicand))

    // radicand - root^2
    output logic [16:0]  remainder
);

    // 32-bit radicand -> 16 groups of 2 bits -> 16 iterations
    localparam int NUM_ITER = 16;
    // Shift register holding the remaining input bit-pairs to process
    logic [31:0] x_reg;
    // Partial / final square-root result
    logic [15:0] q_reg;
    // Signed partial remainder used by the non-restoring algorithm
    // Width is chosen large enough for the intermediate add/sub values
    logic signed [18:0] p_reg;
    // Counts remaining iterations
    logic [4:0] iter_reg;
    // Next 2-bit group pulled from the MSBs of x_reg each cycle
    logic [1:0] next2;
    // Partial remainder after shifting left by 2 and appending next2
    logic signed [18:0] p_shifted;

    // Trial term:
    //   if P >= 0, use (Q<<2)+1
    //   if P <  0, use (Q<<2)+3
    logic signed [18:0] f_val;
    // Next partial remainder after add/subtract
    logic signed [18:0] p_next;
    // Next partial root after appending one new root bit
    logic [15:0] q_next;

    // Grab the current top 2 bits of the radicand shift register
    assign next2 = x_reg[31:30];
    // Shift the current partial remainder left by 2
    // and append the next 2-bit group from the radicand
    assign p_shifted = (p_reg <<< 2) + $signed({17'd0, next2});

    always_comb begin
        // Non-restoring rule:
        // If previous partial remainder is nonnegative, subtract.
        // If previous partial remainder is negative, add.
        if (p_reg >= 0)
            f_val = $signed({1'b0, q_reg, 2'b01}); // (Q << 2) + 1
        else
            f_val = $signed({1'b0, q_reg, 2'b11}); // (Q << 2) + 3

        // Perform the non-restoring add/sub step
        if (p_reg >= 0)
            p_next = p_shifted - f_val;
        else
            p_next = p_shifted + f_val;

        // Append the next root bit based on the sign of the new remainder
        // Nonnegative  -> next root bit = 1
        // Negative     -> next root bit = 0
        if (p_next >= 0)
            q_next = {q_reg[14:0], 1'b1};
        else
            q_next = {q_reg[14:0], 1'b0};
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Asynchronous reset
            x_reg     <= '0;
            q_reg     <= '0;
            p_reg     <= '0;
            iter_reg  <= '0;
            busy      <= 1'b0;
            done      <= 1'b0;
            root      <= '0;
            remainder <= '0;
        end
        else begin
            // done is a one-cycle pulse
            done <= 1'b0;

            // Start a new operation only when the unit is idle
            if (start && !busy) begin
                x_reg     <= radicand;         // load full 32-bit input
                q_reg     <= 16'd0;            // partial root starts at 0
                p_reg     <= 19'sd0;           // partial remainder starts at 0
                iter_reg  <= NUM_ITER[4:0];    // 16 iterations total
                busy      <= 1'b1;
            end
            else if (busy) begin
                // Consume the current top 2 bits and shift next pair into place
                x_reg <= {x_reg[29:0], 2'b00};

                // Update partial root and partial remainder
                q_reg <= q_next;
                p_reg <= p_next;

                // iterate_reg counts down from 16 to 0, and when it reaches 1 we are on the last iteration
                iter_reg <= iter_reg - 1'b1;

                // Last iteration: capture outputs and finish
                if (iter_reg == 5'd1) begin
                    busy <= 1'b0;
                    done <= 1'b1;
                    root <= q_next;

                    // Final correction for non-restoring algorithm:
                    // if the final partial remainder is negative,
                    // restore it once to get the true nonnegative remainder
                    if (p_next < 0)
                        remainder <= p_next + $signed({1'b0, q_next, 1'b1});
                    else
                        remainder <= p_next[16:0];
                end
            end
        end
    end
endmodule