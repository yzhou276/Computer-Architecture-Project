module ceil_log2_32 (
    input  logic [31:0] n,   // Input value
    output logic [5:0]  y    // ceil(log2(n)), range 0 to 32
);

    // For n > 1:
    // ceil(log2(n)) = floor(log2(n - 1)) + 1
    logic [31:0] n_minus_1;

    // Output of the leading-one detector
    logic [4:0]  lod_pos;
    logic        lod_valid;

    // Compute n - 1
    assign n_minus_1 = n - 32'd1;

    // Find the position of the most significant '1' in (n - 1)
    leading_one_detector_32 u_lod (
        .in    (n_minus_1),
        .pos   (lod_pos),
        .valid (lod_valid)
    );

    always_comb begin
        // Special case:
        // n = 0 or n = 1 returns 0
        if (n <= 32'd1) begin
            y = 6'd0;
        end
        else begin
            // For n > 1:
            // result = leading_one_position(n - 1) + 1
            //
            // Example:
            // n = 9
            // n - 1 = 8 = 000...1000
            // leading one position = 3
            // y = 3 + 1 = 4
            y = {1'b0, lod_pos} + 6'd1;
        end
    end

endmodule