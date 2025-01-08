`timescale 1ns / 100ps
module OV76_TO_AXIM_tb;

parameter S_AXI_IDLE = 0;
parameter S_AXI_ADDR = 1;
parameter S_AXI_DATA_S0 = 2;
parameter S_AXI_DATA_S1 = 3;
parameter S_AXI_DATA_F0 = 4;
parameter S_AXI_DATA_F1 = 5;
parameter S_AXI_DATA_F2 = 6;
parameter S_AXI_ACK_S0 = 7;
parameter S_AXI_ACK_S1 = 8;
//parameter S_AXI_ACK_F0 = 6;
//parameter S_AXI_ACK_F1 = 7;

//parameter S_AXI_ACK_F0 = 6;
//parameter S_AXI_ACK_F1 = 7;


//Internal signals declarations:
reg CLK;
reg CLR;

wire [31:0]M_AXI_AWADDR;
wire [1:0]M_AXI_AWBURST;
wire [3:0]M_AXI_AWCACHE;
wire [5:0]M_AXI_AWID;
wire [3:0]M_AXI_AWLEN;
wire [1:0]M_AXI_AWLOCK;
wire [2:0]M_AXI_AWPROT;
wire [3:0]M_AXI_AWQOS;
wire [1:0]M_AXI_AWSIZE;
wire M_AXI_AWVALID;
reg M_AXI_AWREADY;

wire [31:0]M_AXI_WDATA;
wire [5:0]M_AXI_WID;
wire M_AXI_WLAST;
wire [3:0]M_AXI_WSTRB;
wire M_AXI_WVALID;
reg M_AXI_WREADY;

reg [5:0]M_AXI_BID;
reg [1:0]M_AXI_BRESP;
reg M_AXI_BVALID;
wire M_AXI_BREADY;

wire [7:0]CAM_D;
wire CAM_H;
wire CAM_V;
wire CAM_PCLK;
reg CAM_XCLK;
reg [31:0]FRM_ADDR;
reg FRM_RQ;
wire BUSY;
wire IRQ;
reg INTA;
reg CAM_CLR;
reg CAM_PD;

event AXI_W;

// Unit Under Test port map
OV76_TO_AXIM UUT (
	//System signals
	.CLK(CLK),
	.CLR(CLR),
	//AXI Master
	.M_AXI_AWADDR(M_AXI_AWADDR),
	.M_AXI_AWBURST(M_AXI_AWBURST),
	.M_AXI_AWCACHE(M_AXI_AWCACHE),
	.M_AXI_AWID(M_AXI_AWID),
	.M_AXI_AWLEN(M_AXI_AWLEN),
	.M_AXI_AWLOCK(M_AXI_AWLOCK),
	.M_AXI_AWPROT(M_AXI_AWPROT),
	.M_AXI_AWQOS(M_AXI_AWQOS),
	.M_AXI_AWSIZE(M_AXI_AWSIZE),
	.M_AXI_AWVALID(M_AXI_AWVALID),
	.M_AXI_AWREADY(M_AXI_AWREADY),
	.M_AXI_WDATA(M_AXI_WDATA),
	.M_AXI_WID(M_AXI_WID),
	.M_AXI_WLAST(M_AXI_WLAST),
	.M_AXI_WSTRB(M_AXI_WSTRB),
	.M_AXI_WVALID(M_AXI_WVALID),
	.M_AXI_WREADY(M_AXI_WREADY),
	.M_AXI_BID(M_AXI_BID),
	.M_AXI_BRESP(M_AXI_BRESP),
	.M_AXI_BVALID(M_AXI_BVALID),
	.M_AXI_BREADY(M_AXI_BREADY),
	//Camera
	.CAM_D(CAM_D),
	.CAM_H(CAM_H),
	.CAM_V(CAM_V),
	.CAM_PCLK(CAM_PCLK),
	//Control signals
	.FRM_ADDR(FRM_ADDR),
	.FRM_RQ(FRM_RQ),
	.BUSY(BUSY),
	.IRQ(IRQ),
	.INTA(INTA));

OV76_BHV CAM_BHV(
	.XCLK(CAM_XCLK),
	.CLR(CAM_CLR),
	.PD(CAM_PD),
	.PCLK(CAM_PCLK),
	.D(CAM_D),
	.H(CAM_H),
	.V(CAM_V));


initial begin
	forever begin
		CLK = 1'b0;
		#5;
		CLK = 1'b1;
		#5;
	end
end

always begin
	CAM_XCLK = 1'b0;
	repeat(2) @(posedge CLK);
	CAM_XCLK = 1'b1;
	repeat(2) @(posedge CLK);
end

initial begin
	$dumpfile("ov76_to_axim.vcd");
	//$dumpoff;
	$dumpvars(1, UUT);
	//#1_900_000; //Write delay
	$dumpon;
end

initial begin
	repeat(1_228_800) @(negedge CLK);
	$finish;
end

integer AXI_Q;
reg [31:0] AXI_A;
reg [3:0] AXI_C, AXI_AC;
reg [5:0] AXI_ID;
reg AXI_DATA_FAST;
reg AXI_ACK_FAST;
integer TM_DATA;
integer TM_ACK;
integer TM;

initial begin
	AXI_DATA_FAST = 1'b0;
	TM_DATA = 4; //AXI-Slave delay to READY
	CLR = 1'b1; CAM_CLR = 1'b0;	CAM_PD = 1'b0;
	INTA = 1'b0;
	FRM_ADDR = 32'h0000_800C;
	FRM_RQ = 1'b0;
	WAIT(20);
	CLR = 1'b0; CAM_CLR = 1'b1;
	WAIT(10);
	FRM_RQ = 1'b1;
	WAIT(10);
	FRM_RQ = 1'b0;
	repeat(2) @(AXI_W);
	AXI_DATA_FAST = 1'b1;
	$display("AXI Slave - switching to FAST mode.");
end

initial begin
	AXI_Q = S_AXI_IDLE;
	M_AXI_AWREADY = 1'b0;
	M_AXI_WREADY = 1'b0;
	M_AXI_BVALID = 1'b0;
end

//AXI Slave behavioral model
always @(posedge CLK) begin
	M_AXI_AWREADY <= 1'b0;
	M_AXI_WREADY <= 1'b0;
	M_AXI_BVALID <= 1'b0;
	case(AXI_Q)
	S_AXI_IDLE: begin
		if(M_AXI_AWVALID) begin
			AXI_A = M_AXI_AWADDR;
			AXI_C = M_AXI_AWLEN;
			AXI_AC = AXI_C;
			AXI_ID = M_AXI_AWID;
			M_AXI_AWREADY <= 1'b1;
			AXI_Q = S_AXI_ADDR;
		end
	end
	S_AXI_ADDR: begin
		if(AXI_DATA_FAST) begin
			if(M_AXI_WVALID)
				AXI_Q = S_AXI_DATA_F1;
			else
				AXI_Q = S_AXI_DATA_F0;
		end
		else
			AXI_Q = S_AXI_DATA_S0;
	end
	S_AXI_DATA_S0: begin
		//VALID before READY
		if(M_AXI_WVALID) begin
			if(AXI_ID != M_AXI_WID) begin
				$display("Error: Transaction ID differs from address stage. Single pending transaction allowed.");
				$stop;
			end
			M_AXI_WREADY <= 1'b1;
			AXI_Q = S_AXI_DATA_S1;
		end
	end
	S_AXI_DATA_S1: begin
		if(M_AXI_WLAST) begin
			AXI_Q = S_AXI_ACK_S0;
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
			AXI_Q = S_AXI_DATA_S0;
			AXI_C = AXI_C - 1;
		end
	end
	S_AXI_DATA_F0: begin
		if(M_AXI_WVALID) begin
			if(AXI_ID != M_AXI_WID) begin
				$display("Error: Transaction ID differs from address stage. Single pending transaction allowed.");
				$stop;
			end
			M_AXI_WREADY <= 1'b0;
			if(M_AXI_WLAST) begin
				AXI_Q = S_AXI_ACK_S0;
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
			M_AXI_WREADY <= 1'b1;
		end
	end
	S_AXI_DATA_F1: begin
		AXI_Q = S_AXI_DATA_F2;
		M_AXI_WREADY <= 1'b1;
		if(AXI_ID != M_AXI_WID) begin
			$display("Error: Transaction ID differs from address stage. Single pending transaction allowed.");
			$stop;
		end
		if(M_AXI_WLAST) begin
			AXI_Q = S_AXI_ACK_S0;
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
	S_AXI_DATA_F2: begin
		AXI_Q = S_AXI_DATA_F0;
	end
	S_AXI_ACK_S0: begin
		M_AXI_BVALID <= 1'b1;
		M_AXI_BID = AXI_ID;
		if(M_AXI_BREADY) begin
			AXI_Q = S_AXI_ACK_S1;
			M_AXI_BVALID <= 1'b0;
		end
	end
	S_AXI_ACK_S1: begin
		AXI_Q = S_AXI_IDLE;
		->AXI_W;
	end
	endcase
end

task WAIT;
input [31:0] DY;
begin
	repeat(DY) @(negedge CLK);
end
endtask

endmodule


