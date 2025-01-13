`timescale 1ns/100ps

module OV76_TO_AXIM(
    // Global signals
    CLK, CLR,
    //WR - Address channel (transaction init)
    M_AXI_AWADDR,
    M_AXI_AWBURST,
    M_AXI_AWCACHE,
    M_AXI_AWID,
    M_AXI_AWLEN,
    M_AXI_AWLOCK,
    M_AXI_AWPROT,
    M_AXI_AWQOS,
    M_AXI_AWSIZE,
    M_AXI_AWVALID,
    M_AXI_AWREADY,

    //WR - Data channel
    M_AXI_WDATA,
    M_AXI_WID,
    M_AXI_WLAST,
    M_AXI_WSTRB,
    M_AXI_WVALID,
    M_AXI_WREADY,

    //WR - Status channel
    M_AXI_BID,
    M_AXI_BRESP,
    M_AXI_BVALID,
    M_AXI_BREADY,

    //OV7660 - Data interface
    CAM_D,
    CAM_H,
    CAM_V,
    CAM_PCLK,

    //Control signals
    FRM_ADDR,
    FRM_RQ,
    BUSY,
    IRQ,
    INTA
    //Debug signals
  );

  //AXI definitions
  parameter RESP_OK     = 2'b00; //Transaction OK
  parameter RESP_SLVERR = 2'b10; //Slave device not ready
  parameter RESP_DECERR = 2'b11; //No slave device at this address

  parameter BURST_FIXED = 2'b00;
  parameter BURST_INCR  = 2'b01;
  parameter BURST_WRAP  = 2'b10;

  // OV7660 Frame receiver
  parameter FRM_IDLE = 0;
  parameter FRM_START = 1;
  parameter FRM_CAPT_0 = 2;
  parameter FRM_CAPT_1 = 3;
  parameter FRM_CAPT_2 = 4;
  parameter FRM_CAPT_3 = 5;
  parameter FRM_NEW_LINE = 6;

  // AXI Master controller
  parameter MA_IDLE = 0;
  parameter MA_VALID = 1;

  parameter MD_IDLE = 0;
  parameter MD_VALID = 1;
  parameter MD_NEXT = 2;

  parameter MB_IDLE = 0;
  parameter MB_WAIT = 1;
  parameter MB_ACK = 2;

  parameter CTRL_IDLE = 0;
  parameter CTRL_INIT = 1;
  parameter CTRL_TRANS = 2;
  parameter CTRL_WAIT = 3;

  // Global signals
  input CLK;
  input CLR;

  //WR - Address channel (transaction init)
  output [31:0] M_AXI_AWADDR;	//Write address
  output [1:0] M_AXI_AWBURST; //Burst type
  output [3:0] M_AXI_AWCACHE; //Cacheing option
  output [5:0] M_AXI_AWID;	//Transaction ID
  output [3:0] M_AXI_AWLEN;	//Write length
  output [1:0] M_AXI_AWLOCK;	//Transaction lock
  output [2:0] M_AXI_AWPROT;	//Protection
  output [3:0] M_AXI_AWQOS;	//Quality of standard
  output [1:0] M_AXI_AWSIZE;	//Burst size
  output reg M_AXI_AWVALID;		//Valid transaction address + ...
  input M_AXI_AWREADY;		//Transaction address accepted

  //WR - Data channel
  output [31:0] M_AXI_WDATA;
  output [5:0] M_AXI_WID;
  output M_AXI_WLAST;
  output [3:0] M_AXI_WSTRB;
  output M_AXI_WVALID;
  input M_AXI_WREADY;

  //WR - Status channel
  input [1:0] M_AXI_BRESP;
  input [5:0] M_AXI_BID;
  input M_AXI_BVALID;
  output M_AXI_BREADY;

  input [7:0] CAM_D;
  input CAM_H;
  input CAM_V;
  input CAM_PCLK;

  input [31:0] FRM_ADDR;
  input FRM_RQ;
  output BUSY;
  output IRQ;
  input INTA;

  //-----------------------------------------------
  //  Debug
  //-----------------------------------------------
  // output [7:0] DIAG;
  // input [7:0] SW;
  // reg [23:0] PCLK_CNT;


  reg [1:0] CAM_CLK;
  reg [7:0] CAM_DQ;
  reg CAM_HQ;
  reg CAM_VQ;
  reg CAM_CE;

  reg [7:0] FRM_0, FRM_1, FRM_2;
  reg [6:0] FRM_Q = (1 << FRM_IDLE);
  reg FRM_CAP;
  wire FRM_DONE;
  reg [8:0] FRM_CNT;

  // AXI controller
  reg [31:0] M_AXI_AWADDR;
  reg [3:0] M_AXI_AWLEN;	//Write length
  reg [31:0] M_AXI_WDATA;
  // reg [1:0] MD_Q;
  reg [2:0] MD_Q;
  reg [1:0] MB_Q;
  reg [1:0] MA_Q;
  reg [3:0] CTRL_Q;
  reg IRQ;

  reg [31:2] WR_PTR;
  reg [3:0] D_LEN;
  reg [4:0] WR_CNT;
  wire [4:0] WR_CNT_D;
  wire TRANS_RQ;

  reg [9:0] BUF_PTR_W, BUF_PTR_R;
  reg [9:0] BUF_RA;
  reg [10:0] BUF_CNT;
  reg [31:0] BUF [1023:0]; //RAMB16
  wire [31:0] BUF_Q; //Memory (FIFO) read data
  wire BUF_WR;
  wire BUF_RD;
  wire BUF_RDY;
  wire BUF_EMPTY;
  reg BUF_FLUSH;

  ////////////////////////////
  // MY CHANGES
  ////////////////////////////

  wire capture_point = CAM_CE & CAM_HQ;
  reg [9:0] horizontal_cnt = 10'd0;
  reg RE; //Read enable
  wire ongoing_transaction_data;
  assign ongoing_transaction_data = M_AXI_WVALID & M_AXI_WREADY;
  wire ongoing_transaction_address;
  assign ongoing_transaction_address = M_AXI_AWVALID & M_AXI_AWREADY;
  wire ongoing_transaction_response;
  assign ongoing_transaction_response = M_AXI_BVALID & M_AXI_BREADY;
  ////////////////////////////

  ////////////////////////////
  // OV7660 capture logic
  ////////////////////////////
  always @(posedge CLK)
  begin
    CAM_CLK <= {CAM_CLK[0], CAM_PCLK};
    CAM_CE <= CAM_CLK[0] & ~CAM_CLK[1];
    CAM_DQ <= CAM_D;
    CAM_HQ <= CAM_H;
    CAM_VQ <= CAM_V;
    FRM_CAP <= FRM_RQ | (FRM_CAP & ~FRM_DONE);
    //Frame capture	FSM
    //Diagnostic -> Frame counter
    case(1'b1)
      FRM_Q[FRM_IDLE]:
      begin
        FRM_CNT <= 9'd0;
        if(FRM_CAP)
        begin
          FRM_Q <= 1 << FRM_START;
        end
      end
      FRM_Q[FRM_START]:
      begin
        if(CAM_VQ)
        begin
          FRM_CNT <= 9'd0;
          FRM_Q <= 1 << FRM_CAPT_0;
        end
      end
      FRM_Q[FRM_CAPT_0]:
      begin
        if(capture_point)
        begin
          FRM_0 <= CAM_DQ;
          FRM_Q <= 1 << FRM_CAPT_1;
        end
      end
      FRM_Q[FRM_CAPT_1]:
      begin
        if(capture_point)
        begin
          FRM_1 <= CAM_DQ;
          FRM_Q <= 1 << FRM_CAPT_2;
        end
      end
      FRM_Q[FRM_CAPT_2]:
      begin
        if(capture_point)
        begin
          FRM_2 <= CAM_DQ;
          FRM_Q <= 1 << FRM_CAPT_3;
        end
      end
      FRM_Q[FRM_CAPT_3]:
      begin
        if(capture_point)
        begin
          horizontal_cnt <= horizontal_cnt + 10'd1;
          if(horizontal_cnt == 10'd639)
          begin
            FRM_Q <= 1 << FRM_NEW_LINE;
            horizontal_cnt <= 10'd0;
          end
          else
          begin
            FRM_Q <= 1 << FRM_CAPT_0;
          end
        end
      end
      FRM_Q[FRM_NEW_LINE]:
      begin
        if (CAM_HQ && FRM_CNT < 9'd479)
        begin
          FRM_CNT <= FRM_CNT + 9'd1;
          FRM_Q <= 1 << FRM_CAPT_0;
        end
        else if (CAM_HQ && FRM_CNT == 9'd479)
        begin
          FRM_CNT <= 9'd0;
          FRM_Q <= 1 << FRM_START;
        end
      end
    endcase

    //FIFO Buffer
    if(CLR)
    begin
      BUF_PTR_W <= 10'd0;
      BUF_PTR_R <= 10'd0;
      BUF_CNT <= 11'd0;
    end
    else
    begin
      BUF_PTR_W <= BUF_PTR_W + {9'd0, BUF_WR};
      BUF_PTR_R <= BUF_PTR_R + {9'd0, BUF_RD};
      // Update buffer count: +1 on write, -1 on read
      BUF_CNT <= BUF_CNT + {{10{1'b0}}, BUF_WR} - {{10{1'b0}}, BUF_RD};
    end
    //RAMB - dual port memory for FIFO
    if(BUF_WR)
    begin
      //Little endian
      BUF[BUF_PTR_W] <= {CAM_DQ, FRM_2, FRM_1, FRM_0};
      //Big endian
      //BUF[BUF_PTR_W] <= {FRM_2, CAM_DQ, FRM_0, FRM_1};
      //BUF[BUF_PTR_W] <= {1'b0, CAM_DQ[4:0], FRM_2[1:0], CAM_DQ[7:5], FRM_2[6:2], 1'b0, FRM_1[4:0], FRM_0[1:0], FRM_1[7:5], FRM_0[6:2]};
    end

    BUF_FLUSH <= (FRM_DONE | BUF_FLUSH) & ~CTRL_Q[CTRL_IDLE];
    BUF_RA <= BUF_PTR_R;
    // Debug devices
  end

  //////////////////////////
  // AXI Master Address controller
  //////////////////////////
  reg [31:0] write_addr;  // Add register for tracking write address

  always @(posedge CLK)
  begin
    if(CLR)
    begin
      M_AXI_AWADDR <= 32'd0;
      M_AXI_AWVALID <= 1'b0;
      M_AXI_AWLEN <= 4'd15; //16 words burst
      MA_Q <= 1 << MA_IDLE;
      write_addr <= FRM_ADDR;  // Initialize with base address
    end
    else
    begin
      case(1'b1)
      MA_Q[MA_IDLE]:
      begin
        if (CTRL_Q[CTRL_INIT] && BUF_RDY) begin
          M_AXI_AWADDR <= write_addr;
          M_AXI_AWVALID <= 1'b1;
        end
        if (M_AXI_AWREADY && M_AXI_AWVALID)
        begin
          MA_Q <= 1 << MA_VALID;
          M_AXI_AWVALID <= 1'b0;
          write_addr <= write_addr + 32'd64;  // Increment by 64 bytes (16 words)
        end
      end
      MA_Q[MA_VALID]:
      begin
        if (ongoing_transaction_response)
        begin
          MA_Q <= 1 << MA_IDLE;
        end
      end
      endcase
    end
  end

  //////////////////////////
  // FIFO Read Pointer Control
  //////////////////////////
  always @(posedge CLK)
  begin
    if(CLR)
    begin
      BUF_PTR_R <= 10'd0;
    end
    else if(RE)
    begin
      BUF_PTR_R <= BUF_PTR_R + 10'd1;
    end
  end

  //////////////////////////
  // AXI Master Data controller
  //////////////////////////
  always @(posedge CLK)
  begin
    if(CLR)
    begin
      M_AXI_WDATA <= 32'd0;
      WR_CNT <= 5'd0;
      RE <= 1'b0;
      MD_Q <= 1 << MD_IDLE;
    end
    else
    begin
      case(1'b1)
        MD_Q[MD_IDLE]:
        begin
          RE <= 1'b0;
          WR_CNT <= 5'd0;
          if (BUF_RDY && MA_Q[MA_VALID])
          begin
            M_AXI_WDATA <= BUF[BUF_PTR_R];
            MD_Q <= 1 << MD_VALID;
            RE <= 1'b1;
          end
        end
        MD_Q[MD_VALID]:
        begin
          if (M_AXI_WREADY)
          begin
            if (WR_CNT == 4'hF) begin  // Last word of burst
              MD_Q <= 1 << MD_NEXT;
              RE <= 1'b0;
            end else begin
              WR_CNT <= WR_CNT + 1;
              M_AXI_WDATA <= BUF[BUF_PTR_R];
              RE <= 1'b1;
            end
          end
        end
        MD_Q[MD_NEXT]:
        begin
          MD_Q <= 1 << MD_IDLE;
        end
      endcase
    end
  end

  //////////////////////////
  // AXI Master Response controller
  //////////////////////////

  always @(posedge CLK)
  begin
    if(CLR)
    begin
      MB_Q <= 1 << MB_IDLE;
    end
    else
    begin
      case(1'b1)
        MB_Q[MB_IDLE]:
        begin
          if (MA_Q[MA_VALID])
          begin
            MB_Q <= 1 << MB_WAIT;
          end
        end
        MB_Q[MB_WAIT]:
        begin
          if (M_AXI_BVALID)
          begin
            MB_Q <= 1 << MB_ACK;
          end
        end
        MB_Q[MB_ACK]:
        begin
          MB_Q <= 1 << MB_IDLE;
        end
      endcase
    end
  end

  //////////////////////////
  // Control FSM
  //////////////////////////

  always @(posedge CLK)
  begin
    if(CLR)
    begin
      CTRL_Q <= 1 << CTRL_IDLE;
    end
    else
    begin
      case(1'b1)
        CTRL_Q[CTRL_IDLE]:
        begin
          if(FRM_RQ) begin
            CTRL_Q <= 1 << CTRL_INIT;
          end
        end
        CTRL_Q[CTRL_INIT]:
        begin
          if (ongoing_transaction_address && ongoing_transaction_data)
          begin
            CTRL_Q <= 1 << CTRL_TRANS;
          end
        end
        CTRL_Q[CTRL_TRANS]:
        begin
          if (ongoing_transaction_response)
          begin
            CTRL_Q <= 1 << CTRL_WAIT;
          end
        end
        CTRL_Q[CTRL_WAIT]:
        begin
          CTRL_Q <= 1 << CTRL_INIT;
        end
      endcase
    end
  end

  assign WR_CNT_D = (CTRL_Q[CTRL_INIT] ? D_LEN : WR_CNT) + {5'h1F};

  assign BUF_Q = BUF[BUF_RA];

  assign FRM_DONE = FRM_CNT[8] & FRM_CNT[7] & FRM_CNT[6] & FRM_CNT[5]; //480 lines
  assign BUF_WR = FRM_Q[FRM_CAPT_3] & CAM_CE;
  assign BUF_RD =  RE && BUF_RDY;

  assign BUF_RDY = |BUF_CNT[10:4]; //at least 16 items in buffer
  assign BUF_EMPTY = ~|BUF_CNT;

  assign M_AXI_AWBURST = BURST_INCR;
  assign M_AXI_AWSIZE = 2'b10;  //32-bit chunks
  assign M_AXI_AWCACHE = 4'b0000;
  assign M_AXI_AWQOS = 4'b0000;
  assign M_AXI_AWLOCK = 2'b00;
  assign M_AXI_AWPROT = 3'b000;
  assign M_AXI_AWID = 6'b00_1000;

  assign M_AXI_WID = 6'b00_1000;
  assign M_AXI_WVALID = MD_Q[MD_VALID];  // Only valid in MD_VALID state
  assign M_AXI_WLAST = MD_Q[MD_VALID] && (WR_CNT == 4'hF);  // Assert on last word
  assign M_AXI_WSTRB = 4'b1111;

  assign M_AXI_BREADY = MB_Q[1];

endmodule
