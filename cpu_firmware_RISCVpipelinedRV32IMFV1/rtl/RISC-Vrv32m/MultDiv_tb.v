`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/17/2024 12:20:08 PM
// Design Name: 
// Module Name: MultDiv_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module MultDiv_tb(
    );
    reg clk;
    reg reset;
    reg [31:0] a; 
    reg [31:0] b;
    reg [4:0] rs1;
    reg [4:0] rs2;
    reg rv32m;
    reg [2:0] func3;
    wire [31:0] c;
    wire ready;
    
    rv32m_fuseALU rev32m_fuseALU(
        .rv32m(rv32m),
        .a(a),
        .b(b),
        .rs1(rs1),
        .rs2(rs2),
        .func3(func3),
        .clk(clk),
        .clrn(reset),
        .ready(ready),
        .c(c));
        
        
   initial begin     
    #0  clk = 1;
        reset = 0;
    #1  clk = 0;
    #1  clk = 1;
        reset = 1;
        a = 32'h0000aaaa;
        b = 32'h00000002;
        rs1 = 10; //a0 is #10
        rs2 = 11; //a1 is #11
        rv32m = 1;
        func3 = 3; // mulhu
    #1  reset = 1;
    #1  func3 = 0; // mul
    #2  a = 32'hffffffff;
        func3 = 2;
    #2 func3 = 0;
    #2  b = 32'hfffffff0;
        func3 = 1;
    #2  func3 = 0;
    #2  a = 4096;
        b = 511;
        func3 = 4;
    #70 func3 = 6;
    #2 a = -23;
        b = 7;
        func3 = 5;
    #70 func3 = 7;
    #2 b = -7;
        func3 = 4;
    #70 func3 = 6;
    #2 a = 45;
        b = 2;
        func3 = 0;
    #5  $finish;
     
end 
   always #1 clk = !clk;   
endmodule
