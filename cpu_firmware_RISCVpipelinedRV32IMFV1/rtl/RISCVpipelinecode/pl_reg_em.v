module pl_reg_em (ewreg,em2reg,ewmem,eal,edata,erd,clk,clrn,
                      mwreg,mm2reg,mwmem,mal,md,mrd,wremw,mwfpr,ewfpr);
    input clk;
    input clrn;
    input ewreg;
    input em2reg;
    input ewmem;
    input [31:0] eal;
    input [31:0] edata;
    input [4:0] erd;
    output  reg mwreg;
    output reg mm2reg;
    output reg mwmem;
    output reg [31:0] mal;
    output reg [4:0] mrd;
//    output reg [31:0] md;
    output reg [31:0] md;
    input wremw;
    output reg mwfpr;
    input ewfpr;
    
    always @(negedge clrn or posedge clk)
       if (!clrn) begin
        	mwreg <=0;
        	mm2reg <=0;
        	mwmem <=0;
        	mal <=0;
        	mrd <=0;
//        	md <=0;
            md <= 0;
        	mwfpr <= 0;
       end else  begin
 		    mwreg <=ewreg;
       		mm2reg <=em2reg;
       		mwmem <= ewmem;
      		mal <=eal;
       		mrd <=erd;
//       		md <= ed;
            md <= edata;
       		mwfpr <= ewfpr;
       end 
endmodule                       
