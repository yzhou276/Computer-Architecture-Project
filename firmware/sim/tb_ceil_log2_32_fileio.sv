`timescale 1ns/1ps

module tb_ceil_log2_32_fileio;

    logic        clk;
    logic [31:0] n;
    logic [5:0]  y;

    integer infile;
    integer outfile;
    integer r;

    integer unsigned test_val;
    logic [31:0] applied_n;
    logic        have_pending_result;

    ceil_log2_32 dut (
        .n (n),
        .y (y)
    );

    // Clock generation
    initial clk = 1'b0;
    always #5 clk = ~clk;

    initial begin
        infile = $fopen("ceil_log2_test_values.txt", "r");
        if (infile == 0) begin
            $display("ERROR: could not open input file ceil_log2_test_values.txt");
            $finish;
        end

        outfile = $fopen("ceil_log2_sv_results.txt", "w");
        if (outfile == 0) begin
            $display("ERROR: could not open output file ceil_log2_sv_results.txt");
            $finish;
        end

        $fwrite(outfile, "input_dec,input_hex,dut_ceil_log2\n");

        n                   = 32'd0;
        applied_n           = 32'd0;
        have_pending_result = 1'b0;

        // One input applied per clock
        forever begin
            @(posedge clk);

            // First write the result of the previously applied input
            if (have_pending_result) begin
                $fwrite(outfile, "%0d,0x%08h,%0d\n", applied_n, applied_n, y);
            end

            // Then read and apply the next input
            r = $fscanf(infile, "%d", test_val);
            if (r == 1) begin
                n                   <= test_val[31:0];
                applied_n           <= test_val[31:0];
                have_pending_result <= 1'b1;
            end
            else begin
                // No more input values
                @(posedge clk);
                if (have_pending_result) begin
                    $fwrite(outfile, "%0d,0x%08h,%0d\n", applied_n, applied_n, y);
                end

                $fclose(infile);
                $fclose(outfile);
                $display("Done. Results written to ceil_log2_sv_results.txt");
                $finish;
            end
        end
    end

endmodule