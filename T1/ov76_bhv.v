`timescale 1ns/100ps

module OV76_BHV(
	XCLK, CLR, PD,
	PCLK,
	D, H, V);
	
parameter H_CNT = (2 * 784) - 1;	
parameter H_START = (2*640);
parameter H_END = 0;
parameter V_CNT = 510 - 1;
parameter V_START = 489;
parameter V_END = 492;
	
input XCLK;
input CLR;
input PD;
output PCLK;
output [7:0] D;
output H;
output V;

reg [7:0] D;
reg H;
reg V;
reg [10:0] HC;
reg [8:0] VC;
reg [15:0] PIX;
integer PIX_CNT;

assign #2 PCLK = XCLK;

initial begin
	H = 1'b0;
	V = 1'b0;	
	PIX = 16'd0;
	PIX_CNT = 0;
end

always @(negedge PCLK) begin
	if(~CLR) begin
		//Start position - adjust to TB requirements
		HC = H_CNT;
		VC = 477;		
		PIX = 16'd0;
		H = 1'b0;
		V = 1'b0;
	end
	else begin
		if(HC < H_CNT) begin
			HC = HC + 1;
			if(HC == H_START)
				H = 1'b0;
		end
		else begin		
			HC = 11'd0;						
			if(VC < V_CNT) begin
				VC = VC + 1;
			end
			else begin
				VC = 8'd0;				
			end
			if(VC < 480)
				H = 1'b1;
			if(VC == V_START) begin				
				V = 1'b1;				
				$display("Vertical sync - Start of frame");
				PIX_CNT = 0;
			end
			if(VC == V_END) begin
				V = 1'b0;												
			end
		end		
	end
	if((VC < V_START) && H) begin		
		if(HC[0]) begin
			PIX_CNT = PIX_CNT + 1;
			D = PIX[15:8];
			PIX = PIX + 1;
		end
		else begin
			D = PIX[7:0];
		end
	end
	else begin
		D = 8'hxx;
	end
end		
	
endmodule