`timescale 1ns/100ps

module I2C_SLV_BHV(SCL, SDA);
//SDA setup time to SCL posedge
parameter SDA_SU = 40;
//SCL minimal width check
parameter SCL_LO = 40;
parameter SCL_HI = 40;
//Start & Stop check
parameter SCL_H_TO_SDA_H = 30;
parameter SCL_H_TO_SDA_L = 30;
//Devices addresses (ACK response after address) -> Array 
//ADDR_0 - range 0..31
//ADDR_1 - range 32..63
//ADDR_2 - range 64..95
//ADDR_3 - range 96..127
//                         3322_2222_2222_1111_1111_1100_0000_0000 
//                         1098_7654_3210_9876_5432_1098_7654_3210        
parameter ADDR_1F_00 = 32'b0000_0000_0000_0000_0000_0000_0000_0000;  //Active devices: 0x15 (W - 0x2A/R - 0x2B)
parameter ADDR_3F_20 = 32'b0000_0000_0000_0000_0000_0000_0000_0010;	 //                 
parameter ADDR_5F_40 = 32'b0000_0000_0000_0000_0000_0000_0000_0000;	 //                
parameter ADDR_7F_60 = 32'b1000_0000_0000_0000_0000_0000_0000_0000;	 //                
	
inout SCL, SDA;	

//I2C observer states
`define IDLE		0
`define READY		1
`define ADDR_6		2
`define ADDR_5		3
`define ADDR_4		4
`define ADDR_3		5
`define ADDR_2		6
`define ADDR_1		7
`define ADDR_0		8
`define ADDR_RW		9
`define ADDR_ACK	10
`define DATA_WR_7	11
`define DATA_WR_6	12
`define DATA_WR_5	13
`define DATA_WR_4	14
`define DATA_WR_3	15
`define DATA_WR_2	16
`define DATA_WR_1	17
`define DATA_WR_0	18
`define DATA_WR_ACK	19
`define DATA_RD_7	20
`define DATA_RD_6	21
`define DATA_RD_5	22
`define DATA_RD_4	23
`define DATA_RD_3	24
`define DATA_RD_2	25
`define DATA_RD_1	26
`define DATA_RD_0	27
`define DATA_RD_ACK	28

integer STATE;

reg [6:0] ADDR;
reg RW;
reg [7:0] DATA;
reg [7:0] DATA_RD;
reg ACK;
reg SCL_DRV, SDA_DRV;
reg SDA_LAST, SCL_LAST, SCL_HC, SDA_HC;
time SDA_EVENT, SCL_EVENT, SCL_WIDTH, DY;
time SDA_SETUP, SDA_HOLD;

reg [127:0] DEV_ADDR;

//OC drive
assign (pull1, strong0) SDA = (SDA_DRV === 1'b0) ? 1'b0 : 1'bz;
assign (pull1, strong0) SCL = (SCL_DRV === 1'b0) ? 1'b0 : 1'bz;
//Pull-up drive
assign (pull1, strong0) SCL = 1'b1;
assign (pull1, strong0) SDA = 1'b1;

//Model initialization
initial begin
	SDA_DRV = 1'bz;
	SCL_DRV = 1'bz;
	SDA_LAST = SDA;
	SDA_EVENT = 0;
	SDA_HC = 1'b0;
	SCL_LAST = SCL;
	SCL_EVENT = 0;
	SCL_HC = 1'b0;
	ACK = 1'b1;	
	DEV_ADDR = {ADDR_7F_60, ADDR_5F_40, ADDR_3F_20, ADDR_1F_00};
	STATE = `IDLE;
end

specify	
specparam T_SDA_SETUP = 10;
specparam T_SDA_HOLD = 0;
specparam SCL_LOW_MIN = 40;
specparam SCL_HIGH_MIN = 40;
specparam START_STOP_DY = 40;
	$setup(SDA, posedge SCL, T_SDA_SETUP);
	$hold(negedge SCL, SDA, T_SDA_HOLD);
	$setup(SCL, posedge SDA, START_STOP_DY);
	$width(posedge SCL, SCL_HIGH_MIN);
	$width(negedge SCL, SCL_LOW_MIN);
endspecify

always @(SDA) begin	
	if(SCL === 1'b1) begin
		if((SDA_LAST === 1'b1) && (SDA === 1'b0)) begin
			$display("%m (%t): Start condition recievd",$time);
			STATE = `READY;
		end
		else if((SDA_LAST === 1'b0) && (SDA === 1'b1)) begin
			$display("%m (%t): Stop condition recievd",$time);
			STATE = `IDLE;	
		end
		else if((SDA !== 1'b0) && (SDA !== 1'b1)) begin
			$display("%m (%t): Undefined state on SDA line - Going into IDLE state.", $time);
			STATE = `IDLE;
		end
	end
	//SDA timing check
	SDA_EVENT = $time;	
	if(SCL === 1'b1) begin			 		
		if(SDA === 1'b0) begin
			if(DY < SCL_H_TO_SDA_L) begin
				$display("%m (%t) - START condition time violation.\nExpected %t\nObserved %t.", $time, SCL_H_TO_SDA_L, DY);
				$stop;
			end
		end
		if(SDA === 1'b1) begin
			if(DY < SCL_H_TO_SDA_H) begin
				$display("%m (%t) - STOP condition time violation.\nExpected %t\nObserved %t.", $time, SCL_H_TO_SDA_H, DY);
				$stop;
			end			
		end
	end
	SDA_LAST = SDA;
end


//-------------------------------------
//   Read from SDA at
//-------------------------------------
always @(SCL) begin	
	//Read operation
	if(SCL == 1'b1) begin
		case(STATE)
		`ADDR_6: ADDR[6] = SDA;
		`ADDR_5: ADDR[5] = SDA;			
		`ADDR_4: ADDR[4] = SDA;			
		`ADDR_3: ADDR[3] = SDA;			
		`ADDR_2: ADDR[2] = SDA;			
		`ADDR_1: ADDR[1] = SDA;			
		`ADDR_0: ADDR[0] = SDA;			
		`ADDR_RW: RW = SDA;
		`DATA_WR_7: DATA[7] = SDA;		
		`DATA_WR_6: DATA[6] = SDA;		
		`DATA_WR_5: DATA[5] = SDA;
		`DATA_WR_4: DATA[4] = SDA;
		`DATA_WR_3: DATA[3] = SDA;
		`DATA_WR_2: DATA[2] = SDA;
		`DATA_WR_1: DATA[1] = SDA;
		`DATA_WR_0: DATA[0] = SDA;			
		`DATA_RD_ACK: ACK = SDA;
		endcase
	end
	//Change state
	if(SCL == 1'b0) begin
		case(STATE)
		`IDLE:;
		`ADDR_RW: begin
			//Address recieved succesfully - ACK settings
			$display("%m(%t): Address 0x%h",$time, ADDR);
			if(DEV_ADDR[ADDR]) begin
				ACK = 1'b0;
				if(RW == 1'b0)
					$display("Device Active -> Operation : WR");
				else
					$display("Device Active -> Operation : RD");
			end
			else begin
				$display("Device Inactive -> Going into IDLE mode");
			end
			STATE = `ADDR_ACK;
		end
		`ADDR_ACK:
			if(ACK == 1'b0) begin
				if(RW == 1'b0) STATE = `DATA_WR_7;
				else STATE = `DATA_RD_7;								
			end
			else begin
				STATE = `IDLE;
			end
		`DATA_WR_0: begin
			//Data reception - Data processing & ACK settings
			$display("%m(%t) - Data byte recievd -> 0x%h", $time, DATA);
			STATE = `DATA_WR_ACK;
		end
		`DATA_WR_ACK:
			STATE = `DATA_WR_7;			
		`DATA_RD_ACK: begin
			if(ACK == 1'b0) begin
				STATE = `DATA_RD_7;
				$display("%m (%t): READ operation canfirmed (ACK = 0) Going into DATA_READ state.", $time);
			end
			else begin
				STATE = `IDLE;
				$display("%m (%t): READ operation canceled (ACK = 1) Going into IDLE state.", $time);
			end
			//Data RD ACK - further operation
		end
		default:
			STATE = STATE + 1;
		endcase
		//Write operation
		case(STATE)
		`ADDR_ACK, `DATA_WR_ACK: 
			SDA_DRV = ACK;
		`DATA_RD_7:	begin
			DATA = $random;
			$display("%m(%t) Preparing for transmision of: 0x%h", $time, DATA_RD);
			SDA_DRV = DATA_RD[7];
		end
		`DATA_RD_6: SDA_DRV = DATA_RD[6];		
		`DATA_RD_5: SDA_DRV = DATA_RD[5];
		`DATA_RD_4: SDA_DRV = DATA_RD[4];
		`DATA_RD_3: SDA_DRV = DATA_RD[3];
		`DATA_RD_2: SDA_DRV = DATA_RD[2];
		`DATA_RD_1: SDA_DRV = DATA_RD[1];
		`DATA_RD_0: SDA_DRV = DATA_RD[0];
		default: 
			SDA_DRV = 1'bz;
		endcase
	end
	
	//Timimng check block
	SCL_WIDTH = $time - SCL_EVENT;
	SDA_SETUP = $time - SDA_EVENT;
	SCL_EVENT = $time;
	//SCL 0 -> 1 
	if((SCL_LAST === 1'b0) && (SCL === 1'b1)) begin		
		if(SCL_WIDTH < SCL_LO) begin
			$display("%m (%t) - SCL low width time violation.\nExpected %t\nObserved %t.", $time, SCL_LO,  SCL_WIDTH);
			$stop;
		end
		if(SDA_SETUP < SDA_SU) begin
			$display("%m (%t) - SDA to SCL setup time violation.\nExpected %t\nObserved %t.", $time, SDA_SU, SDA_SETUP);
			$stop;
		end		
	end
	//SCL 1 -> 0
	if((SCL_LAST === 1'b1) && (SCL === 1'b0)) begin
		if(SCL_WIDTH < SCL_HI) begin
			$display("%m (%t) - SCL high width time violation.\nExpected %t\nObserved %t.", $time, SCL_HI, SCL_WIDTH);
			$stop;
		end
	end	
	//Remember last value of SCL
	SCL_LAST = SCL;
end

	
endmodule

