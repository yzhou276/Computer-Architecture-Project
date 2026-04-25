module pl_stage_exe(clk, clrn,ea,eb,epc4,ealuc,ecall, ers1, ers2, efunc3, efuse, erv32m, estart_sdivide,estart_udivide,eal, mdwait,zout,eis_fpu,
                    esqrt, estart_sqrt);

	input clk, clrn;
	input   [31:0] ea;
	input   [31:0] eb;
	input [31:0] epc4;
	input [3:0] ealuc;
	input ecall;
	input [2:0] efunc3;
	output efuse;
	input erv32m;
	input [4:0] ers1;
	input [4:0] ers2;
	output [31:0] eal;
	output mdwait;
	output zout;
	input estart_sdivide,estart_udivide;
	input eis_fpu;

	// Integer sqrt accelerator pipeline-control inputs
	input esqrt;        // sustained: current EXE instruction is i_sqrt
	input estart_sqrt;  // 1-cycle pulse to launch the sqrt unit
	
	wire [31:0] ealu;
	wire zout;
	wire [31:0] al;
	wire [31:0] al_md;       // alu | rv32m mux output
	wire [31:0] c_rv32m;

	wire        muldiv_ready;

	// Sqrt accelerator nets
	wire        sqrt_busy;
	wire        sqrt_done;
	wire [15:0] sqrt_root;
	wire [16:0] sqrt_remainder;
	wire [31:0] c_sqrt;
	
	alu alunit (ea,eb,ealuc,ealu,zout,overflow);              // alu
	mux2x32 alu_eal (ealu,epc4,ecall,al);  
	rv32m_fuseALU rv32MD(
	   .rv32m(erv32m),
	   .a(ea),
	   .b(eb),
	   .rs1(ers1),
	   .rs2(ers2),
	   .func3(efunc3),
	   .clk(clk),
	   .clrn(clrn),
	   .ready(muldiv_ready),
	   .c(c_rv32m),
	   .fuse(efuse),
	   .estart_sdivide(estart_sdivide),
	   .estart_udivide(estart_udivide));


    
    // mux2x32 rv32mmux (al,c_rv32m,erv32m,eal);

  	mux2x32 rv32mmux (al,c_rv32m,erv32m,al_md);

    // ------------------------------------------------------------------
    // Integer sqrt accelerator (custom R-type: opcode 0110011, func3 001,
    // func7 0001000). Result is floor(sqrt(rs1)) zero-extended to 32 bits.
    //
    // Stall protocol mirrors the mul/div unit: while estart_sqrt is high
    // (issue cycle) or sqrt_busy is high (iterating), we drop mdwait so
    // that pl_id_cu freezes wpcir/wremw and the sqrt instruction stays
    // in EXE. When the unit deasserts busy, mdwait reasserts and the
    // result is latched into the EXE/MEM pipeline register.
    // ------------------------------------------------------------------
    isqrt32_nonrestoring isqrt_unit (
        .clk       (clk),
        .rst_n     (clrn),
        .start     (estart_sqrt),
        .radicand  (ea),
        .busy      (sqrt_busy),
        .done      (sqrt_done),
        .root      (sqrt_root),
        .remainder (sqrt_remainder));

    // Zero-extend 16-bit floor(sqrt) to 32 bits for the writeback path.
    assign c_sqrt = {16'd0, sqrt_root};

    // Final EXE result mux: alu | mul/div | sqrt
    mux2x32 sqrtmux (al_md, c_sqrt, esqrt, eal);

    // Combine mul/div ready and sqrt activity into mdwait. mdwait is
    // high when EXE may advance; low while either accelerator is busy.
	assign mdwait = muldiv_ready & (~esqrt | sqrt_done);
	
endmodule
