module leading_one_detector_32 (
    input  logic [31:0] in,    // 32-bit input word
    output logic [4:0]  pos,   // Position of highest set bit, 0 to 31
    output logic        valid  // High when at least one bit in 'in' is 1
);

    integer i;

    always_comb begin
        // Default outputs
        pos   = 5'd0;
        valid = 1'b0;

        // Scan from MSB down to LSB
        // The first '1' encountered is the leading one
        for (i = 31; i >= 0; i = i - 1) begin
            // Only take the first match
            if (!valid && in[i]) begin
                pos   = i;
                valid = 1'b1;
            end
        end
    end

endmodule