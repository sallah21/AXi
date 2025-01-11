`timescale 1ns/100ps

// AXI Slave BFM module
module axi_s_bfm #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter RESP_WIDTH = 2,
    parameter AWLEN_WIDTH = 4
  )
  (
    input CLK,
    input RST,
    // AXI signals
    // Address channel
    input [DATA_WIDTH-1:0] AWADDR,
    input [AWLEN_WIDTH-1:0] AWLEN,
    input AWVALID,
    output AWREADY,
    // Data channel
    input [DATA_WIDTH-1:0] WDATA,
    input WVALID,
    output WREADY,
    // Response channel
    output [RESP_WIDTH-1:0] BRESP,
    output BVALID,
    input BREADY
  );

  // AXI Slave state machine states
  parameter S_AXI_IDLE = 2'b00;
  parameter S_AXI_AW   = 2'b01;
  parameter S_AXI_W    = 2'b10;
  parameter S_AXI_B    = 2'b11;

  // State machine registers
  reg [1:0] state;
  reg [1:0] next_state;

  // Response values
  localparam OKAY = 2'b00; // AXI_OKAY - Normal access success
  localparam EXOKAY = 2'b01; // NOT IMPLEMENTED YET: AXI_EXOKAY - Extra cycle access success
  localparam SLVERR = 2'b10; // NOT IMPLEMENTED YET: AXI_SLVERR - Slave error response
  localparam DECERR = 2'b11; // NOT IMPLEMENTED YET: AXI_DECERR - Decode error response

  // Input registers
  reg [ADDR_WIDTH-1:0] AWADDR_reg;
  reg [AWLEN_WIDTH-1:0] AWLEN_reg;
  reg [DATA_WIDTH-1:0] WDATA_reg;

  // Output registers
  reg AWREADY_reg;
  reg WREADY_reg;
  reg [RESP_WIDTH-1:0] BRESP_reg;
  reg BVALID_reg;

  initial begin
    state <= S_AXI_IDLE;
    next_state <= S_AXI_IDLE;
  end

  // State machine
  always @(posedge CLK or negedge RST)
  begin
    if (!RST)
    begin
      state <= S_AXI_IDLE;
      next_state <= S_AXI_IDLE;
    end
    else
    begin
      state <= next_state;
    end
  end

  always @(posedge CLK or negedge RST) begin
    if (!RST) begin
      AWREADY_reg <= 1'b0;
      WREADY_reg <= 1'b0;
      BVALID_reg <= 1'b0;
    end 
    else begin
        case(state)
            S_AXI_IDLE: begin
                AWREADY_reg <= 1'b1;
                WREADY_reg <= 1'b0;
                BVALID_reg <= 1'b0;
                BRESP_reg <= 2'b00;
                if (AWVALID && AWREADY_reg) begin
                    AWREADY_reg <= 1'b0;
                    AWADDR_reg <= AWADDR;
                    AWLEN_reg <= AWLEN;
                    next_state <= S_AXI_AW;
                end
            end
            S_AXI_AW: begin
                WREADY_reg <= 1'b1;
                if (WVALID && WREADY_reg) begin
                    WREADY_reg <= 1'b0;
                    WDATA_reg <= WDATA;
                    next_state <= S_AXI_W;
                end
            end
            S_AXI_W: begin
                WREADY_reg <= 1'b0;
                BVALID_reg <= 1'b1;
                if (BREADY && BVALID_reg) begin
                    BVALID_reg <= 1'b0;
                    BRESP_reg <= OKAY;
                    next_state <= S_AXI_B;
                end
            end
            S_AXI_B: begin
                BVALID_reg <= 1'b0;
                next_state <= S_AXI_IDLE;
            end
        endcase
    end 
  end

  assign AWREADY = AWREADY_reg;
  assign WREADY = WREADY_reg;
  assign BRESP = BRESP_reg;
  assign BVALID = BVALID_reg;

endmodule
