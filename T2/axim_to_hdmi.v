module AXIM_TO_HDMI(
    // System signals
    CLK,
    CLR,
    //VGA Interface control
    EN,
    IMG_EN, /* Enable Video transfer to monitor (0 -> blank screen)  */
    PAT_EN, /* diagnostic pattern enable */
    MESH_EN,
    IMG_BUF,
    IMG_LEN,
    //ADV7511 Configuration interface
    CFG_A, 		//Configuration register address
    CFG_DI,		//Configuration data input
    CFG_DQ,		//Configuration data output
    CFG_WR, 	//Configuration write request (BUSY = 0)
    CFG_RD,		//Configuration read request (BUSY = 0)

    CFG_BUSY,	//Transfer in progress
    CFG_IRQ,	//Interrupt request
    CFG_INTA,	//Interrupt acknowledge (SEI - Specific End of Interrupt)
    CFG_AACK,	//Configuration system address ACK

    //HDMI drivers for ADV7511
    HD_CLK,
    HD_D, HD_DE, HD_HSYNC, HD_VSYNC,
    HD_INT,
    HD_SCL, HD_SDA,
    HD_SPDIF, HD_SPDIFO,

    //AXI-Master read channel
    M_AXI_ARADDR,
    M_AXI_ARBURST,
    M_AXI_ARCACHE,
    M_AXI_ARID,
    M_AXI_ARLEN,
    M_AXI_ARLOCK,
    M_AXI_ARPROT,
    M_AXI_ARQOS,
    M_AXI_ARSIZE,
    M_AXI_ARVALID,
    M_AXI_ARREADY,

    M_AXI_RDATA,
    M_AXI_RID,
    M_AXI_RRESP,
    M_AXI_RLAST,
    M_AXI_RVALID,
    M_AXI_RREADY);

  //VGA config
  //800 : 16 : 96 : 48
  parameter H_MAX = 800;
  parameter H_FP = 16;
  parameter H_SYNC = 96;
  parameter H_BP = 48;
  parameter H_SYNC_START = H_MAX - 16;
  parameter H_SYNC_END = 	H_SYNC_START - 96;
  parameter H_IMG_START = H_SYNC_END - 48;
  //525 -> 480 : 10 :  2 : 33
  parameter V_MAX = 525;
  parameter V_FP = 10;
  parameter V_SYNC = 2;
  parameter V_BP = 33;
  parameter V_SYNC_START = V_MAX - V_FP;
  parameter V_SYNC_END = V_SYNC_START - V_SYNC;
  parameter V_IMG_START = V_SYNC_END - V_BP;

  //AXI R
  parameter R_IDLE		= 3'b001;
  parameter R_DATA		= 3'b010;
  parameter R_DATA_ACK	= 3'b100;

  parameter BURST_FIXED	= 2'b00;
  parameter BURST_INCR	= 2'b01;
  parameter BURST_WRAP	= 2'b10;

  //AXI Master read
  parameter MR_CTRL_W	= 3;
  parameter MR_IDLE	= 3'b000; // 0
  parameter MR_ADDR	= 3'b001; // 1
  parameter MR_AACK	= 3'b011; // 3
  parameter MR_DATA	= 3'b100; // 4
  parameter MR_DACK	= 3'b110; // 6

  //BUF system
  parameter BUF_IDLE 		= 0;
  parameter BUF_INIT 		= 1;
  parameter BUF_CALC_L 	= 2;
  parameter BUF_T_RQ		= 3;
  parameter BUF_CALC_A	= 4;
  parameter BUF_CONT		= 5;

  //ADV7511 Cfg
  parameter CFG_DV_W = 10;

  input CLK;
  input CLR;

  input EN; 		/* Enable VGA controller */
  input IMG_EN;	/* Enable Video transfer to monitor (0 -> blank screen)  */
  input PAT_EN;	/* diagnostic pattern enable */
  input MESH_EN;	/* mesh output */

  input [31:0] IMG_BUF;
  input [17:0] IMG_LEN;

  //ADV7511 Configuration interface
  input [7:0] CFG_A; 		//Configuration register address
  input [7:0] CFG_DI;		//Configuration data input
  output [7:0] CFG_DQ;	//Configuration data output
  input CFG_WR;		 	//Configuration write request (BUSY = 0)
  input CFG_RD;			//Configuration read request (BUSY = 0)

  output CFG_BUSY;	//Transfer in progress
  output CFG_IRQ;		//Interrupt request
  input  CFG_INTA;	//Interrupt acknowledge (SEI - Specific End of Interrupt)
  output CFG_AACK;	//Configuration system address ACK

  reg [CFG_DV_W-1:0] CFG_DV;
  reg CFG_CE;

  //HDMI ADV7511
  output HD_CLK;
  output [15:0] HD_D;
  output HD_DE;
  output HD_HSYNC;
  output HD_VSYNC;
  input HD_INT;
  output HD_SPDIF;
  input HD_SPDIFO;
  inout HD_SCL;
  inout HD_SDA;

  // Read address (issued by master, acceped by Slave)
  /* Read address channel */
  output [31:0] M_AXI_ARADDR;
  output [1:0] M_AXI_ARBURST;
  output [3:0] M_AXI_ARCACHE;
  output [3:0] M_AXI_ARLEN;
  output [5:0] M_AXI_ARID;
  output [1:0] M_AXI_ARLOCK;
  output [2:0] M_AXI_ARPROT;
  output [3:0] M_AXI_ARQOS;
  output [1:0] M_AXI_ARSIZE;
  output M_AXI_ARVALID;
  input M_AXI_ARREADY;

  input [31:0] M_AXI_RDATA;
  input [5:0] M_AXI_RID;
  input [1:0] M_AXI_RRESP;
  input M_AXI_RLAST;
  input M_AXI_RVALID;
  output M_AXI_RREADY;

  //HDMI interface
  reg [15:0] HD_D;
  reg HD_DE;
  reg HD_HSYNC;
  reg HD_VSYNC;
  //VGA controller
  reg [1:0] VGA_DV;
  reg VGA_CE;
  reg [9:0] CNT_V;
  reg V_ZD;
  reg [9:0] CNT_H;
  reg H_ZD;
  reg IMG_V_EN, IMG_EN_Q;
  reg V_LINE;
  reg H_LINE;
  reg IMG_PAT;

  //reg [31:0] VGA_BUF; /* VGA buffer addres */
  //reg [17:0] VGA_LEN; /* VGA buffer length in 32-bit words */

  reg [31:0] M_AXI_ARADDR;
  reg [3:0] M_AXI_ARLEN;
  reg [MR_CTRL_W-1:0] MR_CTRL;

  //FIFO VGA buffer
  reg [31:0] BUF_MEM [511:0];  //RAMB
  wire [31:0] BUF_Q;
  reg [8:0] BUF_RA;
  reg [8:0] BUF_RD_PTR, BUF_WR_PTR;
  reg [9:0] BUF_CNT;
  reg [5:0] BUF_CTRL;
  wire BUF_EN;
  wire BUF_WE, BUF_RD;
  wire BUF_FULL;
  wire BUF_EMPTY;

  reg [31:0] RD_PTR;
  reg [17:0] RD_CNT;
  //reg [3:0] RD_CTRL;
  reg [3:0] RD_RQ_LEN;
  wire RD_RQ;

  assign M_AXI_ARSIZE = 2'b10; //4 bytes
  assign M_AXI_ARID = 6'b00_0011;
  assign M_AXI_ARBURST = BURST_INCR;
  assign M_AXI_ARCACHE = 4'b0000;
  assign M_AXI_ARQOS = 4'b0000;
  assign M_AXI_ARLOCK = 1'b0;
  assign M_AXI_ARPROT = 3'b000;

  assign M_AXI_ARVALID = MR_CTRL[0];
  assign M_AXI_RREADY = MR_CTRL[2];

  always @(posedge CLK)
  begin
    if(CLR)
    begin
      MR_CTRL <= MR_IDLE;
    end
    else
    begin
      //Your implementation of AXI controller
      case(MR_CTRL) /* synthesis parallel_case */
        MR_IDLE:
        begin
			if(EN) begin
				MR_CTRL <= MR_ADDR;
			end
        end
        MR_ADDR:
        begin
			  MR_CTRL <= MR_AACK;
			  M_AXI_ARADDR <= IMG_BUF;
			  M_AXI_ARLEN <= 4'b1111;
        end
        MR_AACK:
        begin
          if(M_AXI_ARREADY)
          begin
            MR_CTRL <= MR_DATA;
          end
        end
        MR_DATA:
        begin
          if(M_AXI_RVALID)
          begin
            MR_CTRL <= MR_DACK;
          end
        end
        MR_DACK:
        begin
			if(M_AXI_RVALID)
			begin
			  if(M_AXI_RLAST)
				MR_CTRL <= MR_ADDR;
			  else
				MR_CTRL <= MR_DATA;
			end
        end
      endcase
    end

    //VGA DMA channel
    if(EN)
    begin
      case(1'b1) /* synthesis parallel_case */
        BUF_CTRL[BUF_IDLE]:
        begin
          if(BUF_EN & IMG_EN)
            BUF_CTRL <= (1 << BUF_INIT);
        end
        BUF_CTRL[BUF_INIT]:
        begin
          BUF_CTRL <= (1 << BUF_CALC_L);
          RD_PTR <= IMG_BUF;
          //RD_CNT <= 153_600; //640 x 480 / 2 (16-bit)
          RD_CNT <= IMG_LEN;
        end
        BUF_CTRL[BUF_CALC_L]:
        begin
          BUF_CTRL <= (1 << BUF_T_RQ);
          if(|RD_CNT[17:4])
            RD_RQ_LEN <= ~RD_PTR[5:2];
          else
            RD_RQ_LEN <= RD_CNT + 4'b1111;
        end
        BUF_CTRL[BUF_T_RQ]:
        begin
          if(MR_CTRL == MR_IDLE)
          begin
            BUF_CTRL <= (1 << BUF_CALC_A);
          end
        end
        BUF_CTRL[BUF_CALC_A]:
        begin
          BUF_CTRL <= (1 << BUF_CONT);
          RD_PTR[31:2] <= RD_PTR[31:2] + RD_RQ_LEN + 1'b1;
          RD_CNT <= RD_CNT + {{14{1'b1}}, ~RD_RQ_LEN};
        end
        BUF_CTRL[BUF_CONT]:
        begin
          if(~BUF_FULL)
          begin
            if(|RD_CNT)
              BUF_CTRL <= (1 << BUF_CALC_L);
            else
              BUF_CTRL <= (1 << BUF_IDLE);
          end
        end
      endcase
    end
    else
    begin
      BUF_CTRL <= (1 << BUF_IDLE);
    end
    //VGA FIFO
    if(EN)
    begin
      BUF_RD_PTR <= BUF_RD_PTR + {9'd0, BUF_RD};
      BUF_WR_PTR <= BUF_WR_PTR + {9'd0, BUF_WE};
      BUF_CNT <= BUF_CNT + {10{BUF_RD}} + {9'd0, BUF_WE};
    end
    else
    begin
      BUF_RD_PTR <= 10'd0;
      BUF_WR_PTR <= 10'd0;
      BUF_CNT <= 11'd0;
    end
    //RAMB FIFO buffer
    if(BUF_WE)
    begin
      BUF_MEM[BUF_WR_PTR] <= M_AXI_RDATA;
    end
    BUF_RA <= BUF_RD_PTR;
  end

  assign BUF_Q = BUF_MEM[BUF_RA];
  assign BUF_EN = (CNT_V == 9'd481);
  assign BUF_FULL = &BUF_CNT[8:5];
  assign BUF_EMPTY = ~|BUF_CNT;
  assign RD_RQ = (BUF_CTRL[BUF_T_RQ]);
  assign BUF_WE = (MR_CTRL[2] & M_AXI_RVALID);
  assign BUF_RD = VGA_CE & IMG_EN & CNT_H[0] & BUF_EMPTY;


  //VGA controller
  always @(posedge CLK)
  begin
    if(EN)
    begin
      if(VGA_CE)
      begin
        if(H_ZD)
        begin
          CNT_H <= (H_MAX - 1);
          if(V_ZD)
          begin
            CNT_V <= (V_MAX - 1);
          end
          else
          begin
            CNT_V <= CNT_V + {10{1'b1}};
          end
        end
        else
        begin
          CNT_H <= CNT_H + {10{1'b1}};
        end
        //Color driver
        if(IMG_EN_Q)
        begin
          HD_D <= CNT_H[0] ? BUF_Q[31:16] : BUF_Q[15:0];
          //VGA_R <= {4{VGA_IMG_EN}} & (CNT_H[0] ? BUF_Q[19:16] : BUF_Q[3:0]) | {4{IMG_PAT}};
          //VGA_G <= {4{VGA_IMG_EN}} & (CNT_H[0] ? BUF_Q[23:20] : BUF_Q[7:4]) | {4{IMG_PAT}};
          //VGA_B <= {4{VGA_IMG_EN}} & (CNT_H[0] ? BUF_Q[27:24] : BUF_Q[11:8]) | {4{IMG_PAT}};
        end
        else
        begin
          //Blank
          HD_D <= 16'h0080;
          //VGA_R <= 4'd0;
          //VGA_G <= 4'd0;
          //VGA_B <= 4'd0;
        end
      end
    end
    else
    begin
      CNT_H <= 10'd0;
      CNT_V <= 10'd0;
      //VGA_H <= 1'b1;
      //VGA_V <= 1'b1;
      //VGA_R <= 4'd0;
      //VGA_G <= 4'd0;
      //VGA_B <= 4'd0;
    end
    H_ZD <= ~|CNT_H;
    V_ZD <= ~|CNT_V;
    HD_HSYNC <= ~(H_SYNC_START == CNT_H) & ((H_SYNC_END == CNT_H) | ~EN | HD_HSYNC);
    //VGA_H <= ~(H_SYNC_START == CNT_H) & ((H_SYNC_END == CNT_H) | ~VGA_EN | VGA_H);
    HD_VSYNC <= ~(V_SYNC_START == CNT_V) & ((V_SYNC_END == CNT_V) | ~EN | HD_VSYNC);
    //VGA_V <= ~(V_SYNC_START == CNT_V) & ((V_SYNC_END == CNT_V) | ~VGA_EN | VGA_V);
    IMG_V_EN <= ((V_IMG_START == CNT_V) | IMG_V_EN) & ~V_ZD & EN;
    //IMG_EN <= ((H_IMG_START == CNT_H) | IMG_EN) & ~H_ZD & IMG_V_EN;
    HD_DE <= ((H_IMG_START == CNT_H) | HD_DE) & ~H_ZD & IMG_V_EN;
    {VGA_CE, VGA_DV} <= ({2{EN}} &  VGA_DV) + {1'b0, EN};
    H_LINE <= (CNT_H[4:0] == 5'b00001) | (CNT_H[9] & CNT_H[7]);
    V_LINE <= (CNT_V[4:0] == 5'b00000) | (CNT_V[8:0] == 9'd1);
    IMG_PAT <= PAT_EN & (MESH_EN ? (H_LINE | V_LINE) : (H_LINE & V_LINE));
    //PIX_CNT <= ({19{IMG_V_EN}} & PIX_CNT) + {{18{1'b0}},(VGA_CE & IMG_EN)};
    {CFG_CE, CFG_DV} <= ({CFG_DV_W{~CLR}} & CFG_DV) + 1'b1;
  end

  assign HD_SPDIF = 1'b0;

endmodule

