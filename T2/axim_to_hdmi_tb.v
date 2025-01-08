`timescale 1ns / 100ps
module AXIM_TO_HDMI_tb;

defparam UUT.CFG_DV_W = 10;
parameter CFG_DV_W = 10;

//Internal signals declarations:
reg CLK;
reg CLR;
reg EN;
reg IMG_EN;
reg PAT_EN;
reg MESH_EN;
reg [31:0]IMG_BUF;
reg [17:0]IMG_LEN;
reg [7:0]CFG_A;
reg [7:0]CFG_DI;
wire [7:0]CFG_DQ;
reg CFG_WR;
reg CFG_RD;
wire CFG_BUSY;
wire CFG_IRQ;
reg CFG_INTA;
wire CFG_AACK;
wire HD_CLK;
wire [15:0]HD_D;
wire HD_DE;
wire HD_HSYNC;
wire HD_VSYNC;
reg HD_INT;

tri HD_SCL;
reg HD_SCL_DRV;
//Continous assignment for inout port "HD_SCL".
assign HD_SCL = HD_SCL_DRV;

tri HD_SDA;
reg HD_SDA_DRV;
//Continous assignment for inout port "HD_SDA".
assign HD_SDA = HD_SDA_DRV;

wire HD_SPDIF;
reg HD_SPDIFO;

wire [31:0]AXI_B1_AWADDR;
wire [1:0]AXI_B1_AWBURST;
wire [3:0]AXI_B1_AWCACHE;
wire [5:0]AXI_B1_AWID;
wire [3:0]AXI_B1_AWLEN;
wire [1:0]AXI_B1_AWLOCK;
wire [2:0]AXI_B1_AWPROT;
wire [3:0]AXI_B1_AWQOS;
wire [1:0]AXI_B1_AWSIZE;
wire AXI_B1_AWVALID;
wire AXI_B1_AWREADY;
wire [31:0]AXI_B1_WDATA;
wire [5:0]AXI_B1_WID;
wire AXI_B1_WLAST;
wire [3:0]AXI_B1_WSTRB;
wire AXI_B1_WVALID;
wire AXI_B1_WREADY;
wire [5:0]AXI_B1_BID;
wire [1:0]AXI_B1_BRESP;
wire AXI_B1_BVALID;
wire AXI_B1_BREADY;
wire [31:0]AXI_B1_ARADDR;
wire [1:0]AXI_B1_ARBURST;
wire [3:0]AXI_B1_ARCACHE;
wire [5:0]AXI_B1_ARID;
wire [3:0]AXI_B1_ARLEN;
wire [1:0]AXI_B1_ARLOCK;
wire [2:0]AXI_B1_ARPROT;
wire [3:0]AXI_B1_ARQOS;
wire [1:0]AXI_B1_ARSIZE;
wire AXI_B1_ARVALID;
wire AXI_B1_ARREADY;
wire [31:0]AXI_B1_RDATA;
wire [5:0]AXI_B1_RID;
wire AXI_B1_RLAST;
wire AXI_B1_RREADY;
wire [1:0]AXI_B1_RRESP;
wire AXI_B1_RVALID;

// Unit Under Test port map
AXIM_TO_HDMI #(.CFG_DV_W(4))UUT (
	.CLK(CLK),
	.CLR(CLR),

	.EN(EN),
	.IMG_EN(IMG_EN),
	.PAT_EN(PAT_EN),
	.MESH_EN(MESH_EN),
	.IMG_BUF(IMG_BUF),
	.IMG_LEN(IMG_LEN),

	.CFG_A(CFG_A),
	.CFG_DI(CFG_DI),
	.CFG_DQ(CFG_DQ),
	.CFG_WR(CFG_WR),
	.CFG_RD(CFG_RD),
	.CFG_BUSY(CFG_BUSY),
	.CFG_IRQ(CFG_IRQ),
	.CFG_INTA(CFG_INTA),
	.CFG_AACK(CFG_AACK),

	.HD_CLK(HD_CLK),
	.HD_D(HD_D),
	.HD_DE(HD_DE),
	.HD_HSYNC(HD_HSYNC),
	.HD_VSYNC(HD_VSYNC),
	.HD_INT(HD_INT),

	.HD_SPDIF(HD_SPDIF),
	.HD_SPDIFO(HD_SPDIFO),

	.HD_SCL(HD_SCL),
	.HD_SDA(HD_SDA),

	.M_AXI_ARADDR(AXI_B1_ARADDR),
	.M_AXI_ARBURST(AXI_B1_ARBURST),
	.M_AXI_ARCACHE(AXI_B1_ARCACHE),
	.M_AXI_ARID(AXI_B1_ARID),
	.M_AXI_ARLEN(AXI_B1_ARLEN),
	.M_AXI_ARLOCK(AXI_B1_ARLOCK),
	.M_AXI_ARPROT(AXI_B1_ARPROT),
	.M_AXI_ARQOS(AXI_B1_ARQOS),
	.M_AXI_ARSIZE(AXI_B1_ARSIZE),
	.M_AXI_ARVALID(AXI_B1_ARVALID),
	.M_AXI_ARREADY(AXI_B1_ARREADY),
	.M_AXI_RDATA(AXI_B1_RDATA),
	.M_AXI_RID(AXI_B1_RID),
	.M_AXI_RRESP(AXI_B1_RRESP),
	.M_AXI_RLAST(AXI_B1_RLAST),
	.M_AXI_RVALID(AXI_B1_RVALID),
	.M_AXI_RREADY(AXI_B1_RREADY));


AXI_4_S_BFM BFM_S1(
	.S_AXI_ACLK(CLK),
	.S_AXI_ARESETN(~CLR),

	.S_AXI_AWADDR(AXI_B1_AWADDR),
	.S_AXI_AWBURST(AXI_B1_AWBURST),
	.S_AXI_AWCACHE(AXI_B1_AWCACHE),
	.S_AXI_AWID(AXI_B1_AWID),
	.S_AXI_AWLEN(AXI_B1_AWLEN),
	.S_AXI_AWLOCK(AXI_B1_AWLOCK),
	.S_AXI_AWPROT(AXI_B1_AWPROT),
	.S_AXI_AWQOS(AXI_B1_AWQOS),
	.S_AXI_AWSIZE(AXI_B1_AWSIZE),
	.S_AXI_AWVALID(AXI_B1_AWVALID),
	.S_AXI_AWREADY(AXI_B1_AWREADY),

	.S_AXI_WDATA(AXI_B1_WDATA),
	.S_AXI_WID(AXI_B1_WID),
	.S_AXI_WLAST(AXI_B1_WLAST),
	.S_AXI_WSTRB(AXI_B1_WSTRB),
	.S_AXI_WVALID(AXI_B1_WVALID),
	.S_AXI_WREADY(AXI_B1_WREADY),
	.S_AXI_BID(AXI_B1_BID),
	.S_AXI_BRESP(AXI_B1_BRESP),
	.S_AXI_BVALID(AXI_B1_BVALID),
	.S_AXI_BREADY(AXI_B1_BREADY),

	.S_AXI_ARADDR(AXI_B1_ARADDR),
	.S_AXI_ARBURST(AXI_B1_ARBURST),
	.S_AXI_ARCACHE(AXI_B1_ARCACHE),
	.S_AXI_ARID(AXI_B1_ARID),
	.S_AXI_ARLEN(AXI_B1_ARLEN),
	.S_AXI_ARLOCK(AXI_B1_ARLOCK),
	.S_AXI_ARPROT(AXI_B1_ARPROT),
	.S_AXI_ARQOS(AXI_B1_ARQOS),
	.S_AXI_ARSIZE(AXI_B1_ARSIZE),
	.S_AXI_ARVALID(AXI_B1_ARVALID),
	.S_AXI_ARREADY(AXI_B1_ARREADY),

	.S_AXI_RDATA(AXI_B1_RDATA),
	.S_AXI_RID(AXI_B1_RID),
	.S_AXI_RLAST(AXI_B1_RLAST),
	.S_AXI_RREADY(AXI_B1_RREADY),
	.S_AXI_RRESP(AXI_B1_RRESP),
	.S_AXI_RVALID(AXI_B1_RVALID));

initial begin
	CLR = 1'b1;
	EN = 1'b0;
	IMG_EN = 1'b0;
	PAT_EN = 1'b0;
	MESH_EN = 1'b0;
	IMG_BUF = 32'h0001_001C;
	IMG_LEN = 18'd153600;
	CFG_A = 8'h41; CFG_DI = 8'h55;
	CFG_WR = 1'b0;
	CFG_RD = 1'b0;
	CFG_INTA = 1'b0;
	WAIT(4);
	CLR = 1'b0;
	WAIT(10);
	EN = 1'b1;
	WAIT(153_600);
	$finish();
end

initial begin
	CLK = 1'b0;
	forever
		#5 CLK = ~CLK;
end

initial begin
	$dumpfile("axim_to_hdmi.vcd");
	//$dumpoff;
	$dumpvars(1, UUT);
	//#1_900_000; //Write delay
	$dumpon;
end

task WAIT;
input [31:0] DY;
begin
	repeat(DY) @(negedge CLK);
end
endtask

endmodule
