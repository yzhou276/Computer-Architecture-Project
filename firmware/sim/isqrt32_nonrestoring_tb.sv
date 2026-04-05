`timescale 1ns/1ps

module isqrt32_nonrestoring_tb;

    // ------------------------------------------------------------------------
    // DUT interface signals
    // ------------------------------------------------------------------------
    logic         clk;
    logic         rst_n;
    logic         start;
    logic [31:0]  radicand;
    logic         busy;
    logic         done;
    logic [15:0]  root;
    logic [16:0]  remainder;

    // ------------------------------------------------------------------------
    // Instantiate DUT
    // ------------------------------------------------------------------------
    isqrt32_nonrestoring dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .start     (start),
        .radicand  (radicand),
        .busy      (busy),
        .done      (done),
        .root      (root),
        .remainder (remainder)
    );

    // ------------------------------------------------------------------------
    // Clock generation: 100 MHz
    // ------------------------------------------------------------------------
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // ------------------------------------------------------------------------
    // File handles and test variables
    // ------------------------------------------------------------------------
    integer infile;
    integer logfile;
    integer status;
    integer test_count;
    integer pass_count;
    integer fail_count;

    int unsigned file_val;
    int unsigned expected_root;
    int unsigned expected_remainder;

    // ------------------------------------------------------------------------
    // Reference function: floor(sqrt(x)) for 32-bit unsigned input
    // ------------------------------------------------------------------------
    function automatic int unsigned ref_isqrt32(input int unsigned x);
        int unsigned lo;
        int unsigned hi;
        int unsigned mid;
        longint unsigned mid_sq;
        begin
            lo = 0;
            hi = 32'h0000FFFF;

            while (lo <= hi) begin
                mid = lo + ((hi - lo) >> 1);
                mid_sq = longint'(mid) * longint'(mid);

                if (mid_sq == x) begin
                    return mid;
                end
                else if (mid_sq < x) begin
                    lo = mid + 1;
                end
                else begin
                    if (mid == 0)
                        return 0;
                    hi = mid - 1;
                end
            end

            return hi;
        end
    endfunction

    // ------------------------------------------------------------------------
    // Task: run one DUT transaction
    // ------------------------------------------------------------------------
    task automatic run_one_test(input int unsigned x);
        begin
            // Drive input
            @(posedge clk);
            radicand <= x;
            start    <= 1'b1;

            // One-cycle start pulse
            @(posedge clk);
            start    <= 1'b0;

            // Wait for done
            wait (done == 1'b1);

            // Compute reference values
            expected_root      = ref_isqrt32(x);
            expected_remainder = x - (expected_root * expected_root);

            test_count++;

            // Save one line to log file
            // Format:
            // test_value, expected_floor_sqrt, expected_remainder, dut_root, dut_remainder, pass_fail
            $fwrite(logfile, "%0d,%0d,%0d,%0d,%0d,%s\n",
                    x,
                    expected_root,
                    expected_remainder,
                    root,
                    remainder,
                    ((root === expected_root[15:0]) &&
                     (remainder === expected_remainder[16:0])) ? "PASS" : "FAIL");

            // Compare DUT vs reference
            if ((root === expected_root[15:0]) &&
                (remainder === expected_remainder[16:0])) begin
                pass_count++;
                $display("PASS: x=0x%08X (%0d), root=%0d, rem=%0d",
                         x, x, root, remainder);
            end
            else begin
                fail_count++;
                $display("FAIL: x=0x%08X (%0d)", x, x);
                $display("      DUT: root=%0d rem=%0d", root, remainder);
                $display("      REF: root=%0d rem=%0d",
                         expected_root, expected_remainder);
            end

            @(posedge clk);
        end
    endtask

    // ------------------------------------------------------------------------
    // Main stimulus
    // ------------------------------------------------------------------------
    initial begin
        // Initialize signals
        rst_n      = 1'b0;
        start      = 1'b0;
        radicand   = 32'd0;
        test_count = 0;
        pass_count = 0;
        fail_count = 0;

        // Apply reset
        repeat (5) @(posedge clk);
        rst_n = 1'b1;
        repeat (2) @(posedge clk);

        // Open input file
        infile = $fopen("nonrestoring_isqrt_test_values.txt", "r");
        if (infile == 0) begin
            $error("Could not open nonrestoring_isqrt_test_values.txt");
            $finish;
        end

        // Open output log file
        logfile = $fopen("nonrestoring_isqrt_results.txt", "w");
        if (logfile == 0) begin
            $error("Could not open nonrestoring_isqrt_results.csv for writing");
            $finish;
        end

        // Write CSV header
        $fwrite(logfile,
            "test_value,floor_sqrt,remainder,dut_root,dut_remainder,result\n");

        $display("Starting non-restoring integer sqrt tests...");

        // Read one decimal integer per line until EOF
        while (!$feof(infile)) begin
            status = $fscanf(infile, "%d\n", file_val);

            if (status == 1) begin
                run_one_test(file_val);
            end
        end

        $fclose(infile);
        $fclose(logfile);

        // Summary
        $display("--------------------------------------------------");
        $display("Test summary:");
        $display("  Total tests : %0d", test_count);
        $display("  Passed      : %0d", pass_count);
        $display("  Failed      : %0d", fail_count);
        $display("--------------------------------------------------");
        $display("Log written to nonrestoring_isqrt_results.csv");

        if (fail_count == 0)
            $display("All tests passed.");
        else
            $display("Some tests failed.");

        $finish;
    end

endmodule