module pl_reg_mw(mwreg,mm2reg,mm,mal,mrd,clk,clrn,wwreg,wm2reg,wm,wal,wrd,wremw,mwfpr,wwfpr);

	input mwreg;
	input mm2reg;
	input [31:0] mm;
	input [31:0] mal;
	input [4:0] mrd;
	input clk;
	input clrn;
	output reg wwreg;
	output reg wm2reg;
	output reg [31:0] wm;
	output reg [31:0] wal;
	output reg [4:0] wrd;
	input wremw;
	input mwfpr;
	output reg wwfpr;
	
    always @(negedge clrn or posedge clk)
       if (!clrn) begin
        	wwreg <=0;
        	wm2reg <=0;
        	wal <=0;
        	wm <=0;
        	wrd <=0;
        	wwfpr <= 0;
       end else begin
//       if (wremw==1)begin
        	wwreg <=mwreg;
        	wm2reg <=mm2reg;
        	wal <=mal;
        	wm <=mm;
        	wrd <=mrd;
            wwfpr <= mwfpr;

       end 
endmodule                       
	
