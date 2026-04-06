`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/11/2024 02:05:48 AM
// Design Name: 
// Module Name: rev32_mult
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


module rv32_mult(
    input [31:0] a,
    input [31:0] b,
    input [2:0] func3,
    input clk,
    output reg [31:0] lower_product,
    output reg [31:0] upper_product
    );
    reg [63:0] product;
    //reg  [31:0] lower_product;
    //reg  [31:0] upper_product;
    
    always @(*) begin
       if(func3==1'h0)
           begin
             product = a*b;
             lower_product = product[31:0];
             upper_product = product[63:32];
           end    
       if(func3==1'h1)
           begin
             product = $signed(a)*$signed(b);
             lower_product = product[31:0];
             upper_product = product[63:32];
           end    
       if(func3==1'h2)
           begin
             product = $signed(a)*b;
             lower_product = product[31:0];
             upper_product = product[63:32];
           end    
       if(func3==1'h3)
           begin
             product = a*b;
             lower_product = product[31:0];
             upper_product = product[63:32];
           end    
    end
endmodule
