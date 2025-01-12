//AXI-4 Slave interface
`timescale 1ns/100ps

module AXI_4_S_BFM(
	S_AXI_ACLK, /* Global clock signal - Master port */
	S_AXI_ARESETN,
	//WR - Address channel (transaction init)
	S_AXI_AWADDR,
	S_AXI_AWBURST,
	S_AXI_AWCACHE,
	S_AXI_AWID,
	S_AXI_AWLEN,
	S_AXI_AWLOCK,
	S_AXI_AWPROT,
	S_AXI_AWQOS,
	S_AXI_AWSIZE,
	S_AXI_AWVALID,
	S_AXI_AWREADY,
	//WR - Data channel
	S_AXI_WDATA,
	S_AXI_WID,
	S_AXI_WLAST,
	S_AXI_WSTRB,
	S_AXI_WVALID,
	S_AXI_WREADY,
	//WR - Status channel
	S_AXI_BID,
	S_AXI_BRESP,
	S_AXI_BVALID,
	S_AXI_BREADY,
	//RD - Address channel
	S_AXI_ARADDR,
	S_AXI_ARBURST,
	S_AXI_ARCACHE,
	S_AXI_ARID,
	S_AXI_ARLEN,
	S_AXI_ARLOCK,
	S_AXI_ARPROT,
	S_AXI_ARQOS,
	S_AXI_ARSIZE,
	S_AXI_ARVALID,
	S_AXI_ARREADY,
	//RD - Data channel
	S_AXI_RDATA,
	S_AXI_RID,
	S_AXI_RLAST,
	S_AXI_RREADY,
	S_AXI_RRESP,
	S_AXI_RVALID);

parameter R_IDLE = 0;
parameter R_ADDR = 1;
parameter R_A_WAIT = 2;
parameter R_DATA = 3;
parameter R_D_WAIT = 4;

parameter W_IDLE = 0;
parameter W_ADDR = 1;
parameter W_DATA_S0 = 2;
parameter W_DATA_S1 = 3;
parameter W_DATA_F0 = 4;
parameter W_DATA_F1 = 5;
parameter W_DATA_F2 = 6;
parameter W_ACK_S0 = 7;
parameter W_ACK_S1 = 8;

input S_AXI_ACLK; 			// Global clock signal - Master port
input S_AXI_ARESETN;

input [31:0] S_AXI_AWADDR;	//Write address
input [1:0] S_AXI_AWBURST; //Burst type
input [3:0] S_AXI_AWCACHE; //Cacheing option
input [5:0] S_AXI_AWID;	//Transaction ID
input [3:0] S_AXI_AWLEN;	//Write length
input [1:0] S_AXI_AWLOCK;	//Transaction lock
input [2:0] S_AXI_AWPROT;	//Protection
input [3:0] S_AXI_AWQOS;	//Quality of standard
input [1:0] S_AXI_AWSIZE;	//Burst size
input S_AXI_AWVALID;		//Valid transaction address + ...
output reg S_AXI_AWREADY;		//Transaction address accepted

input [31:0] S_AXI_WDATA;	//Write data
input [5:0] S_AXI_WID; 	//Transaction ID
input [3:0] S_AXI_WSTRB;
input S_AXI_WLAST;
input S_AXI_WVALID;
output reg S_AXI_WREADY;

output reg [5:0] S_AXI_BID;
output reg [1:0] S_AXI_BRESP;
output reg S_AXI_BVALID;
input S_AXI_BREADY;

input [31:0] S_AXI_ARADDR;
input [1:0] S_AXI_ARBURST;
input [3:0] S_AXI_ARCACHE;
input [5:0] S_AXI_ARID;
input [3:0] S_AXI_ARLEN;
input [1:0] S_AXI_ARLOCK;
input [2:0] S_AXI_ARPROT;
input [3:0] S_AXI_ARQOS;
input [1:0] S_AXI_ARSIZE;
input S_AXI_ARVALID;
output S_AXI_ARREADY;

output [31:0] S_AXI_RDATA;
output [5:0] S_AXI_RID;
output [1:0] S_AXI_RRESP;
output S_AXI_RLAST;
output S_AXI_RVALID;
input S_AXI_RREADY;

integer R_CTRL;
reg [3:0] R_LEN;

integer RA_DY;
integer RD_DY;
integer T_DY;
reg [31:0] R_DQ;
reg [31:0] A_DQ;
reg [5:0] R_ID;

//Write channel internal
integer W_CTRL;
reg [31:0] AXI_A;
reg [3:0] AXI_C, AXI_AC;
reg [5:0] AXI_ID;
reg AXI_DATA_FAST;
reg AXI_ACK_FAST;
integer TM_DATA;
integer TM_ACK;
integer TM;
event AXI_W;

initial begin
	//Read channel
	R_CTRL = R_IDLE;
	RA_DY = 1;
	RD_DY = 1;
	R_DQ = 32'h01_00_0000;
	//Write channel
	W_CTRL = W_IDLE;
	S_AXI_AWREADY = 1'b0;
	S_AXI_WREADY = 1'b0;
	S_AXI_BVALID = 1'b0;
end

assign S_AXI_ARREADY = (R_CTRL == R_ADDR) ? 1'b1 : 1'b0;
assign S_AXI_RVALID = (R_CTRL == R_DATA) ? 1'b1 : 1'b0;
assign S_AXI_RLAST = (R_CTRL == R_DATA) ? ((R_LEN == 0) ? 1'b1 : 1'b0) : 1'bx;
assign S_AXI_RDATA = (R_CTRL == R_DATA) ? R_DQ : 32'hxxxx_xxxx;
assign S_AXI_RID = (R_CTRL == R_DATA) ? R_ID : 6'hxx;
assign S_AXI_RRESP = (R_CTRL == R_ADDR) ? 2'b00 : 2'bxx;

always @(posedge S_AXI_ACLK) begin
	//Read channel - response controller
	if(S_AXI_ARESETN) begin
		case(R_CTRL)
		R_IDLE: begin
			if(S_AXI_ARVALID) begin
				if(RA_DY)
					R_CTRL <= R_A_WAIT;
				else
					R_CTRL <= R_ADDR;
				T_DY = RA_DY;
			end
		end
		R_ADDR: begin
			$display("AXI slave %m - Read address ACK.");
			if(RD_DY) begin
				T_DY = RD_DY;
				R_CTRL = R_D_WAIT;
			end
			else
				R_CTRL = R_DATA;
			A_DQ = S_AXI_ARADDR;
			R_LEN = S_AXI_ARLEN;
			R_ID = S_AXI_ARID;
		end
		R_A_WAIT: begin
			T_DY = T_DY - 1;
			if(T_DY == 0) begin
				R_CTRL <= R_ADDR;
			end
		end
		R_DATA: begin
			$display("AXI Slave %m - Read data RDY.");
			if(S_AXI_RREADY) begin
				$display("AXI Slave %m - Read data master ACK.");
				R_DQ = R_DQ + 1;
				if(R_LEN) begin
					R_LEN = R_LEN - 1;
					if(RD_DY) begin
						R_CTRL <= R_D_WAIT;
						T_DY = RD_DY;
					end
				end
				else begin
					R_CTRL <= R_IDLE;
				end
			end
		end
		R_D_WAIT: begin
			T_DY = T_DY - 1;
			if(T_DY == 0)
				R_CTRL <= R_DATA;
		end
		endcase
	end
	else begin
		R_CTRL = R_IDLE;
	end

	//-------------------------------------------
	//  Write channel
	//-------------------------------------------
	if(S_AXI_ARESETN) begin //Normal operation
		S_AXI_AWREADY <= 1'b0;
		S_AXI_WREADY <= 1'b0;
		S_AXI_BVALID <= 1'b0;
		case(W_CTRL)
		W_IDLE: begin
			if(S_AXI_AWVALID) begin
				AXI_A = S_AXI_AWADDR;
				AXI_C = S_AXI_AWLEN;
				AXI_AC = AXI_C;
				AXI_ID = S_AXI_AWID;
				S_AXI_AWREADY <= 1'b1;
				W_CTRL = W_ADDR;
			end
		end
		W_ADDR: begin
			if(AXI_DATA_FAST) begin
				if(S_AXI_WVALID)
					W_CTRL = W_DATA_F1;
				else
					W_CTRL = W_DATA_F0;
			end
			else
				W_CTRL = W_DATA_S0;
		end
		W_DATA_S0: begin
			//VALID before READY
			if(S_AXI_WVALID) begin
				if(AXI_ID != S_AXI_WID) begin
					$display("Error: Transaction ID differs from address stage. Single pending transaction allowed.");
					$stop;
				end
				S_AXI_WREADY <= 1'b1;
				W_CTRL = W_DATA_S1;
			end
		end
		W_DATA_S1: begin
			if(S_AXI_WLAST) begin
				W_CTRL = W_ACK_S0;
				if(AXI_C != 0) begin
					$display("Error: Missing chunks of transaction - AXI_WLAST asserted to early.");
					$stop;
				end
				else begin
					$display("Info: Transaction completed %h[0..%d].", AXI_A, AXI_AC);
				end
			end
			else begin
				if(AXI_C == 0) begin
					$display("Error: Last burst cycle -> AXI_WLAST not asserted.");
					$stop;
				end
				W_CTRL = W_DATA_S0;
				AXI_C = AXI_C - 1;
			end
		end
		W_DATA_F0: begin
			if(S_AXI_WVALID) begin
				if(AXI_ID != S_AXI_WID) begin
					$display("Error: Transaction ID differs from address stage. Single pending transaction allowed.");
					$stop;
				end
				S_AXI_WREADY <= 1'b0;
				if(S_AXI_WLAST) begin
					W_CTRL = W_ACK_S0;
					if(AXI_C != 0) begin
						$display("Error: Missing chunks of transaction - AXI_WLAST asserted to early.");
						$stop;
					end
					else begin
					   $display("Info: Transaction completed %h[0..%d].", AXI_A, AXI_AC);
					end
				end
				else begin
					if(AXI_C == 0) begin
						$display("Error: Last burst cycle -> AXI_WLAST not asserted.");
						$stop;
					end
				end
				AXI_C = AXI_C - 1;
			end
			else begin
				S_AXI_WREADY <= 1'b1;
			end
		end
		W_DATA_F1: begin
			W_CTRL = W_DATA_F2;
			S_AXI_WREADY <= 1'b1;
			if(AXI_ID != S_AXI_WID) begin
				$display("Error: Transaction ID differs from address stage. Single pending transaction allowed.");
				$stop;
			end
			if(S_AXI_WLAST) begin
				W_CTRL = W_ACK_S0;
				if(AXI_C != 0) begin
					$display("Error: Missing chunks of transaction - AXI_WLAST asserted to early.");
					$stop;
				end
				else begin
				   $display("Info: Transaction completed %h[0..%d].", AXI_A, AXI_AC);
				end
			end
			else begin
				if(AXI_C == 0) begin
					$display("Error: Last burst cycle -> AXI_WLAST not asserted.");
					$stop;
				end
			end
			AXI_C = AXI_C - 1;
		end
		W_DATA_F2: begin
			W_CTRL = W_DATA_F0;
		end
		W_ACK_S0: begin
			S_AXI_BVALID <= 1'b1;
			S_AXI_BID = AXI_ID;
			if(S_AXI_BREADY) begin
				W_CTRL = W_ACK_S1;
				S_AXI_BVALID <= 1'b0;
			end
		end
		W_ACK_S1: begin
			W_CTRL = W_IDLE;
			->AXI_W;
		end
		endcase
	end
	else begin
		S_AXI_AWREADY <= 1'b0;
		S_AXI_WREADY <= 1'b0;
		S_AXI_BVALID <= 1'b0;
	end
end



endmodule

