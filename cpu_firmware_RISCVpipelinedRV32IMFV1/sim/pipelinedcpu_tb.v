/************************************************
  The Verilog HDL code example is from the book
  Computer Principles and Design in Verilog HDL
  by Yamin Li, published by A JOHN WILEY & SONS
************************************************/


`timescale 1ns/1ns
`include "mfp_ahb_const.vh"
module pipelinedcpu_tb;
     // Decode stage variables (current)
    reg [8*8 :1] opcode; 
    reg [8*28:1] desc;
    reg [8*5 :1] rs;
    reg [8*5 :1] rt;
    reg [8*5 :1] rd;
    reg [31:0] imm;
    reg [31:0] branch_addr;
    reg [31:0] jump_addr;
    wire is_fpu;

    // Pipeline stage variables - store complete decoded instruction info
    reg [8*8 :1] opcode_e, opcode_m, opcode_w; 
    reg [8*28:1] desc_e, desc_m, desc_w;
    reg [8*5 :1] rs_e, rt_e, rd_e;
    reg [8*5 :1] rs_m, rt_m, rd_m;
    reg [8*5 :1] rs_w, rt_w, rd_w;

    // Pipeline tracking
    reg [31:0] pc_e, pc_m, pc_w;
    reg [31:0] instr_e, instr_m, instr_w;
    reg [31:0] prev_pc;
    reg pc_stalled;

    wire [31:0] instr_spy = pipelinedcpu_tb.cpu.inst;
    wire [31:0] pc4_spy   = pipelinedcpu_tb.cpu.pc;

    reg         clk, clrn;
    wire        lock = 1'b1;
    reg  [31:0] counter;
    reg         intr;

    // DUT observable buses
    wire [31:0] pc, inst, eal, mal, wres;
    wire [31:0] e3d, wd;
    wire  [4:0] e1n, e2n, e3n, wn;
    wire        ww, stl_lw, stl_fp, stl_lwc1, stl_swc1, stl;

    // Stall detection - CORRECTED to use wpcir signal
    reg explicit_stall;
    reg wpcir_stall;
    always @* begin
        explicit_stall = 1'b0;
        if (stl == 1'b1) explicit_stall = 1'b1;
        if (stl_lw == 1'b1) explicit_stall = 1'b1;
        if (stl_fp == 1'b1) explicit_stall = 1'b1;
        if (stl_lwc1 == 1'b1) explicit_stall = 1'b1;
        if (stl_swc1 == 1'b1) explicit_stall = 1'b1;
        
        // CORRECTED: Use wpcir signal for PC freeze detection
        wpcir_stall = (wpcir == 1'b0);  // wpcir goes low when PC should freeze
    end

    // IOs & headers
    reg  [`MFP_N_SW-1 :0] IO_Switch;
    reg  [`MFP_N_PB-1 :0] IO_PB;
    wire [`MFP_N_LED-1:0] IO_LED;
    wire [7:0]            IO_7SEGEN_N;
    wire [6:0]            IO_7SEG_N;
    wire                  IO_BUZZ;
    wire [10:1]           JC;
    wire [4:1]            JA;
    wire [8:1]            JB;
    reg                   UART_RX;
    assign JA[3] = 1'b0;
    reg memclk;
    wire wpcir;

    // Counter
    always @(posedge clk) begin
        if (!clrn) begin
            counter <= 0;
        end else begin
            counter <= counter + 1;
        end
    end

    // Track PC changes to detect stalls
    always @(posedge clk or negedge clrn) begin
        if (!clrn) begin
            prev_pc <= 32'h0;
            pc_stalled <= 1'b0;
        end else begin
            prev_pc <= pc4_spy;
            pc_stalled <= (pc4_spy == prev_pc) && clrn;
        end
    end

    // CORRECTED: Pipeline tracking using wpcir signal
    always @(posedge clk or negedge clrn) begin
        if (!clrn) begin
            pc_e <= 32'h0; pc_m <= 32'h0; pc_w <= 32'h0;
            instr_e <= 32'h0; instr_m <= 32'h0; instr_w <= 32'h0;
            opcode_e <= "ZERO    "; opcode_m <= "ZERO    "; opcode_w <= "ZERO    ";
            desc_e <= "Zero instruction"; desc_m <= "Zero instruction"; desc_w <= "Zero instruction";
            rs_e <= "N/A  "; rt_e <= "N/A  "; rd_e <= "N/A  ";
            rs_m <= "N/A  "; rt_m <= "N/A  "; rd_m <= "N/A  ";
            rs_w <= "N/A  "; rt_w <= "N/A  "; rd_w <= "N/A  ";
        end
        else begin
            // DEBUG for first 10 cycles and during stalls
            if (counter < 10 || wpcir_stall || explicit_stall) begin
                $display("DEBUG Cycle %d: pc4_spy=%h, instr_spy=%h, wpcir=%b, wpcir_stall=%b, explicit_stall=%b", 
                         counter, pc4_spy, instr_spy, wpcir, wpcir_stall, explicit_stall);
                $display("  BEFORE: pc_e=%h, opcode_e=%s", pc_e, opcode_e);
            end
            
            // CORRECTED: Use wpcir_stall instead of pc_stalled
            if (wpcir_stall || explicit_stall) begin
                // STALL: Only memory and writeback advance
                // Execute and decode stages stay the same (preserve DIVU in execute, REMU in decode)
                pc_w <= pc_m;
                pc_m <= pc_e;
                // pc_e stays the same - DIVU remains in execute
                
                instr_w <= instr_m;
                instr_m <= instr_e;
                // instr_e stays the same - DIVU remains in execute
                
                opcode_w <= opcode_m;
                opcode_m <= opcode_e;
                // opcode_e stays the same - DIVU remains in execute
                
                desc_w <= desc_m;
                desc_m <= desc_e;
                // desc_e stays the same - DIVU remains in execute
                
                rs_w <= rs_m; rt_w <= rt_m; rd_w <= rd_m;
                rs_m <= rs_e; rt_m <= rt_e; rd_m <= rd_e;
                // Execute stage registers stay the same - DIVU preserved
                // Decode stage registers also stay the same - REMU stays in decode
                
                if (counter < 10 || (counter % 4 == 0)) begin
                    $display("  STALL: pc_e=%h (unchanged), opcode_e=%s (unchanged)", pc_e, opcode_e);
                    $display("  STALL: DECODE stays %s, EXECUTE stays %s", opcode, opcode_e);
                end
            end else begin
                // NORMAL: All stages advance
                pc_w <= pc_m;
                pc_m <= pc_e;
                pc_e <= pc4_spy;
                
                instr_w <= instr_m;
                instr_m <= instr_e;
                instr_e <= instr_spy;
                
                opcode_w <= opcode_m;
                opcode_m <= opcode_e;
                opcode_e <= opcode;  // Save current decode stage opcode
                
                desc_w <= desc_m;
                desc_m <= desc_e;
                desc_e <= desc;      // Save current decode stage description
                
                rs_w <= rs_m; rt_w <= rt_m; rd_w <= rd_m;
                rs_m <= rs_e; rt_m <= rt_e; rd_m <= rd_e;
                rs_e <= rs; rt_e <= rt; rd_e <= rd;  // Save current decode stage registers
                
                if (counter < 10) begin
                    $display("  ADVANCE: pc_e=%h->%h, opcode_e=%s->%s", pc_e, pc4_spy, opcode_e, opcode);
                end
            end
        end
    end

    // Function to get register name
    function [8*5:1] get_reg_name;
        input [4:0] reg_num;
        begin
            case (reg_num)
                5'd0: get_reg_name = "x0   "; 5'd1: get_reg_name = "x1   "; 5'd2: get_reg_name = "x2   "; 5'd3: get_reg_name = "x3   ";
                5'd4: get_reg_name = "x4   "; 5'd5: get_reg_name = "x5   "; 5'd6: get_reg_name = "x6   "; 5'd7: get_reg_name = "x7   ";
                5'd8: get_reg_name = "x8   "; 5'd9: get_reg_name = "x9   "; 5'd10: get_reg_name = "x10  "; 5'd11: get_reg_name = "x11  ";
                5'd12: get_reg_name = "x12  "; 5'd13: get_reg_name = "x13  "; 5'd14: get_reg_name = "x14  "; 5'd15: get_reg_name = "x15  ";
                5'd16: get_reg_name = "x16  "; 5'd17: get_reg_name = "x17  "; 5'd18: get_reg_name = "x18  "; 5'd19: get_reg_name = "x19  ";
                5'd20: get_reg_name = "x20  "; 5'd21: get_reg_name = "x21  "; 5'd22: get_reg_name = "x22  "; 5'd23: get_reg_name = "x23  ";
                5'd24: get_reg_name = "x24  "; 5'd25: get_reg_name = "x25  "; 5'd26: get_reg_name = "x26  "; 5'd27: get_reg_name = "x27  ";
                5'd28: get_reg_name = "x28  "; 5'd29: get_reg_name = "x29  "; 5'd30: get_reg_name = "x30  "; 5'd31: get_reg_name = "x31  ";
                default: get_reg_name = "N/A  ";
            endcase
        end
    endfunction

    // CORRECTED: Comprehensive instruction decoding with descriptions
    always @* begin
        imm = {instr_spy[31:12], 12'b0}; 
        branch_addr = {{20{instr_spy[31]}}, instr_spy[31:20], 2'b00}; 
        jump_addr = {pc4_spy[31:12], instr_spy[31:12], 2'b00}; 
        
        // Default values
        opcode = "N/A     ";
        desc = "undefined instruction";
        rs = get_reg_name(instr_spy[19:15]);
        rt = get_reg_name(instr_spy[24:20]);
        rd = get_reg_name(instr_spy[11:7]);
        
        // Special cases first
        if (instr_spy == 32'h00000013) begin
            opcode = "NOP     ";
            desc = "No operation (addi x0,x0,0)";
            rs = "x0   "; rt = "N/A  "; rd = "x0   ";
        end else if (instr_spy == 32'h00000000) begin
            opcode = "ZERO    ";
            desc = "Zero instruction";
            rs = "N/A  "; rt = "N/A  "; rd = "N/A  ";
        end else begin
            // Instruction decoding logic - RESTORED from older testbench
            case (instr_spy[6:0])
                7'b0110011: begin // R-type and RV32M
                    if (instr_spy[31:25] == 7'b0000001) begin // RV32M instructions
                        case (instr_spy[14:12])
                            3'b000: begin opcode = "MUL     "; desc = "rd = rs1 * rs2"; end
                            3'b001: begin opcode = "MULH    "; desc = "rd = (rs1 * rs2) >> 32 (signed high)"; end
                            3'b010: begin opcode = "MULHSU  "; desc = "rd = (rs1 * rs2) >> 32 (signed/unsigned)"; end
                            3'b011: begin opcode = "MULHU   "; desc = "rd = (rs1 * rs2) >> 32 (unsigned high)"; end
                            3'b100: begin opcode = "DIV     "; desc = "rd = rs1 / rs2"; end
                            3'b101: begin opcode = "DIVU    "; desc = "rd = rs1 / rs2 (unsigned)"; end
                            3'b110: begin opcode = "REM     "; desc = "rd = rs1 % rs2"; end
                            3'b111: begin opcode = "REMU    "; desc = "rd = rs1 % rs2 (unsigned)"; end
                            default: begin opcode = "N/A     "; desc = "undefined M-type op"; end
                        endcase
                    end else if (instr_spy[31:25] == 7'b0001000) begin      // custom log2 and sqrt
                        case (instr_spy[14:12])
                            3'b000: begin opcode = "LOG2    "; desc = "rd = floor(log2(rs1))"; end
                            3'b001: begin opcode = "SQRT    "; desc = "rd = sqrt(rs1)"; end
                            default: begin opcode = "N/A     "; desc = "undefined custom op"; end
                        endcase
                    end else begin // Standard R-type instructions
                        case (instr_spy[14:12])
                            3'b000: begin 
                                case (instr_spy[30])
                                    1'b0: begin opcode = "ADD     "; desc = "rd = rs1 + rs2"; end
                                    1'b1: begin opcode = "SUB     "; desc = "rd = rs1 - rs2"; end
                                endcase
                            end
                            3'b111: begin opcode = "AND     "; desc = "rd = rs1 & rs2"; end
                            3'b110: begin opcode = "OR      "; desc = "rd = rs1 | rs2"; end
                            3'b100: begin opcode = "XOR     "; desc = "rd = rs1 ^ rs2"; end
                            3'b001: begin opcode = "SLL     "; desc = "rd = rs1 << rs2[4:0]"; end
                            3'b101: begin 
                                case (instr_spy[30]) 
                                    1'b0: begin opcode = "SRL     "; desc = "rd = rs1 >> rs2[4:0]"; end
                                    1'b1: begin opcode = "SRA     "; desc = "rd = rs1 >>> rs2[4:0]"; end
                                endcase
                            end
                            3'b010: begin opcode = "SLT     "; desc = "rd = (rs1 < rs2) ? 1 : 0"; end
                            3'b011: begin opcode = "SLTU    "; desc = "rd = (rs1 < rs2) ? 1 : 0"; end
                            default: begin opcode = "N/A     "; desc = "undefined R-type op"; end
                        endcase
                    end
                end 

                7'b0000111: begin // LOAD (non-standard opcode used by your assembler)
                    case (instr_spy[14:12])
                        3'b000: begin opcode = "LB      "; desc = "rd = *(char*)(offset + rs1)"; end
                        3'b001: begin opcode = "LH      "; desc = "rd = *(short*)(offset + rs1)"; end
                        3'b010: begin 
                            if (is_fpu == 1'b1) begin
                                opcode = "FLW     "; 
                                desc = "rd = *(float*)(offset + rs1)";
                            end else begin
                                opcode = "LW      "; 
                                desc = "rd = *(int*)(offset + rs1)";
                            end
                        end
                        3'b100: begin opcode = "LBU     "; desc = "rd = *(unsigned char*)(offset + rs1)"; end
                        3'b101: begin opcode = "LHU     "; desc = "rd = *(unsigned short*)(offset + rs1)"; end
                        default: begin opcode = "N/A     "; desc = "undefined LOAD op"; end
                    endcase
                end 

                7'b0000011: begin // LOAD (standard RISC-V opcode)
                    case (instr_spy[14:12])
                        3'b000: begin opcode = "LB      "; desc = "rd = *(char*)(offset + rs1)"; end
                        3'b001: begin opcode = "LH      "; desc = "rd = *(short*)(offset + rs1)"; end
                        3'b010: begin 
                            if (is_fpu == 1'b1) begin
                                opcode = "FLW     "; 
                                desc = "rd = *(float*)(offset + rs1)";
                            end else begin
                                opcode = "LW      "; 
                                desc = "rd = *(int*)(offset + rs1)";
                            end
                        end
                        3'b100: begin opcode = "LBU     "; desc = "rd = *(unsigned char*)(offset + rs1)"; end
                        3'b101: begin opcode = "LHU     "; desc = "rd = *(unsigned short*)(offset + rs1)"; end
                        default: begin opcode = "N/A     "; desc = "undefined LOAD op"; end
                    endcase
                end 

                7'b0010011: begin // I-type immediate
                    case (instr_spy[14:12])
                        3'b000: begin opcode = "ADDI    "; desc = "rd = rs1 + imm"; end
                        3'b111: begin opcode = "ANDI    "; desc = "rd = rs1 & imm"; end
                        3'b110: begin opcode = "ORI     "; desc = "rd = rs1 | imm"; end
                        3'b100: begin opcode = "XORI    "; desc = "rd = rs1 ^ imm"; end
                        3'b001: begin opcode = "SLLI    "; desc = "rd = rs1 << shamt"; end
                        3'b101: begin 
                            case (instr_spy[30])
                                1'b0: begin opcode = "SRLI    "; desc = "rd = rs1 >> shamt"; end
                                1'b1: begin opcode = "SRAI    "; desc = "rd = rs1 >>> shamt"; end
                            endcase
                        end
                        3'b010: begin opcode = "SLTI    "; desc = "rd = (rs1 < imm) ? 1 : 0"; end
                        3'b011: begin opcode = "SLTIU   "; desc = "rd = (rs1 < imm) ? 1 : 0"; end
                        default: begin opcode = "N/A     "; desc = "undefined I-type op"; end
                    endcase
                end 

                7'b1100011: begin // BRANCH
                    case (instr_spy[14:12])
                        3'b000: begin opcode = "BEQ     "; desc = "if (rs1 == rs2) pc += offset * 4"; end
                        3'b001: begin opcode = "BNE     "; desc = "if (rs1 != rs2) pc += offset * 4"; end
                        3'b100: begin opcode = "BLT     "; desc = "if (rs1 < rs2) pc += offset * 4"; end
                        3'b101: begin opcode = "BGE     "; desc = "if (rs1 >= rs2) pc += offset * 4"; end
                        3'b110: begin opcode = "BLTU    "; desc = "if (rs1 < rs2) pc += offset * 4"; end
                        3'b111: begin opcode = "BGEU    "; desc = "if (rs1 >= rs2) pc += offset * 4"; end
                        default: begin opcode = "N/A     "; desc = "undefined branch op"; end
                    endcase
                end 

                7'b0100111: begin // STORE (non-standard opcode)
                    case (instr_spy[14:12])
                        3'b000: begin opcode = "SB      "; desc = "*(char*)(offset + rs1) = rs2"; end
                        3'b001: begin opcode = "SH      "; desc = "*(short*)(offset + rs1) = rs2"; end
                        3'b010: begin 
                            if (is_fpu == 1'b1) begin
                                opcode = "FSW     "; 
                                desc = "*(float*)(offset + rs1) = rs2";
                            end else begin
                                opcode = "SW      "; 
                                desc = "*(int*)(offset + rs1) = rs2";
                            end
                        end
                        default: begin opcode = "N/A     "; desc = "undefined store op"; end
                    endcase
                end

                7'b0100011: begin // STORE (standard RISC-V opcode)
                    case (instr_spy[14:12])
                        3'b000: begin opcode = "SB      "; desc = "*(char*)(offset + rs1) = rs2"; end
                        3'b001: begin opcode = "SH      "; desc = "*(short*)(offset + rs1) = rs2"; end
                        3'b010: begin 
                            if (is_fpu == 1'b1) begin
                                opcode = "FSW     "; 
                                desc = "*(float*)(offset + rs1) = rs2";
                            end else begin
                                opcode = "SW      "; 
                                desc = "*(int*)(offset + rs1) = rs2";
                            end
                        end
                        default: begin opcode = "N/A     "; desc = "undefined store op"; end
                    endcase
                end
                            
                7'b1101111: begin opcode = "JAL     "; desc = "rd = pc + 4, pc = target address"; end 
                7'b1100111: begin opcode = "JALR    "; desc = "rd = pc + 4, pc = (rs1 + imm) & ~1"; end 
                7'b0110111: begin opcode = "LUI     "; desc = "rd = imm"; end
                7'b0010111: begin opcode = "AUIPC   "; desc = "rd = pc + imm"; end

                7'b1110011: begin // System instructions
                    case (instr_spy[14:12])
                        3'b000: begin 
                            case (instr_spy[31:20])
                                12'h000: begin opcode = "ECALL   "; desc = "Environment call"; end
                                12'h001: begin opcode = "EBREAK  "; desc = "Environment break"; end
                                12'h302: begin opcode = "MRET    "; desc = "Machine return from trap"; end
                                default: begin opcode = "N/A     "; desc = "undefined privileged op"; end
                            endcase
                        end                    
                        3'b001: begin opcode = "CSRRW   "; desc = "rd = CSR; CSR = rs1"; end
                        3'b010: begin opcode = "CSRRS   "; desc = "rd = CSR; CSR |= rs1"; end
                        3'b011: begin opcode = "CSRRC   "; desc = "rd = CSR; CSR &= ~rs1"; end
                        3'b101: begin opcode = "CSRRWI  "; desc = "rd = CSR; CSR = imm"; end
                        3'b110: begin opcode = "CSRRSI  "; desc = "rd = CSR; CSR |= imm"; end
                        3'b111: begin opcode = "CSRRCI  "; desc = "rd = CSR; CSR &= ~imm"; end
                        default: begin opcode = "N/A     "; desc = "undefined system op"; end
                    endcase
                end 
                
                7'b1010011: begin // Floating Point Ops (RV32F) - RESTORED
                    case (instr_spy[31:25])
                        7'b0000000: begin opcode = "FADD.S  "; desc = "rd = rs1 + rs2 (FP single precision)"; end
                        7'b0000100: begin opcode = "FSUB.S  "; desc = "rd = rs1 - rs2 (FP single precision)"; end
                        7'b0001000: begin opcode = "FMUL.S  "; desc = "rd = rs1 * rs2 (FP single precision)"; end
                        7'b0001100: begin opcode = "FDIV.S  "; desc = "rd = rs1 / rs2 (FP single precision)"; end
                        7'b0101100: begin opcode = "FSQRT.S "; desc = "rd = sqrt(rs1) (FP single precision)"; end
                        default: begin opcode = "N/A     "; desc = "undefined FP op"; end
                    endcase
                end
              
                default: begin opcode = "N/A     "; desc = "undefined instruction"; end
            endcase
        end
    end

    // Pipeline display
    always @(posedge clk) begin
        if (clrn && (counter[1:0] == 2'b00)) begin
            $display("=== Pipeline State (Cycle %d) ===", counter);
            if (wpcir_stall || explicit_stall) $display("*** PIPELINE STALLED (wpcir=%b) ***", wpcir);
            $display("DECODE:    PC=%h %s %s rs=%s rt=%s rd=%s", pc4_spy, opcode, desc, rs, rt, rd);
            $display("EXECUTE:   PC=%h %s %s rs=%s rt=%s rd=%s", pc_e, opcode_e, desc_e, rs_e, rt_e, rd_e);
            $display("MEMORY:    PC=%h %s %s rs=%s rt=%s rd=%s", pc_m, opcode_m, desc_m, rs_m, rt_m, rd_m);
            $display("WRITEBACK: PC=%h %s %s rs=%s rt=%s rd=%s", pc_w, opcode_w, desc_w, rs_w, rt_w, rd_w);
            $display("Stalls: stl=%b stl_lw=%b stl_fp=%b stl_lwc1=%b stl_swc1=%b wpcir=%b", stl, stl_lw, stl_fp, stl_lwc1, stl_swc1, wpcir);
            $display("=========================================");
        end
    end

    // CPU instantiation
    pl_computer cpu(
        .SI_CLK100MHZ(memclk), .lock(lock), .SI_ClkIn(clk), .SI_Reset_N(clrn),                  
        .pc(pc), .inst(inst), .eal(eal), .mal(mal), .wres(wres), .e3d(e3d), .wd(wd),
        .e1n(e1n), .e2n(e2n), .e3n(e3n), .wn(wn), .ww(ww),
        .stl_lw(stl_lw), .stl_fp(stl_fp), .stl_lwc1(stl_lwc1), .stl_swc1(stl_swc1), .stl(stl),
        .IO_Switch(IO_Switch), .IO_PB(IO_PB), .IO_LED(IO_LED), .IO_7SEGEN_N(IO_7SEGEN_N), .IO_7SEG_N(IO_7SEG_N), 
        .IO_BUZZ(IO_BUZZ), .IO_RGB_SPI_MOSI(JC[2]), .IO_RGB_SPI_SCK(JC[4]), .IO_RGB_SPI_CS(JC[1]),
        .IO_RGB_DC(JC[7]), .IO_RGB_RST(JC[8]), .IO_RGB_VCC_EN(JC[9]), .IO_RGB_PEN(JC[10]),
        .IO_CS(JA[1]), .IO_SCK(JA[4]), .IO_SDO(JA[3]), .UART_RX(UART_RX), .JB(JB),.is_fpu(is_fpu),
        .wpcir(wpcir)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    // Memory clock generation
    initial begin
        memclk = 0;
        forever #5 memclk = ~memclk;
    end

    // Reset signal
    initial begin
        clrn = 0;
        #25 clrn = 1;
    end
    
    initial begin
        intr = 0;
    end
    
    // IO Switch simulation
    initial begin
        IO_Switch = 16'haaaa;
        forever 
         #100 IO_Switch = ~IO_Switch;
    end

    // Initialize other IO signals
    initial begin
        IO_PB = 0;
        UART_RX = 1;
    end

    // Simulation control
    initial begin
        #8000; // Run for 8000ns to see the DIVU stall behavior
        $display("=== SIMULATION COMPLETED ===");
        $finish;
    end
                
endmodule
