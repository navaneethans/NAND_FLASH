/* Verilog netlist generated by SCUBA Diamond (64-bit) 3.3.0.109  Patch Version(s) 122746 */
/* Module Version: 7.4 */
/* C:\lscc\diamond\3.3_x64\ispfpga\bin\nt64\scuba.exe -w -n ebr_buffer -lang verilog -synth synplify -bus_exp 7 -bb -arch mj5g00 -type bram -wp 11 -rp 1010 -data_width 8 -rdata_width 8 -num_rows 2048 -outdataA REGISTERED -outdataB REGISTERED -writemodeA NORMAL -writemodeB NORMAL -resetmode ASYNC -cascade -1  */
/* Mon Nov 10 22:18:45 2014 */
//
/////
//`timescale 1 ns / 1 ps
//module ebr_buffer (DataInA, DataInB, AddressA, AddressB, ClockA, ClockB, 
//    ClockEnA, ClockEnB, WrA, WrB, ResetA, ResetB, QA, QB);
//    input  [7:0] DataInA;
//    input  [7:0] DataInB;
//    input  [10:0] AddressA;
//    input  [10:0] AddressB;
//    input  ClockA;
//    input  ClockB;
//    input  ClockEnA;
//    input  ClockEnB;
//    input  WrA;
//    input  WrB;
//    input  ResetA;
//    input  ResetB;
//    output reg [7:0] QA;
//    output reg [7:0] QB;
//
//reg       [7:0]  block_ramA[0:2047];
//reg       [7:0]  block_ramB[0:2047];
////port A
//always @ ( posedge ClockA )
//begin
//if(ResetA)
//QA <= 8'd0;
//else if(ClockEnA)begin
//	if(WrA)
//		block_ramA[AddressA] <= DataInA;
//	else	
//		QA <= block_ramA[AddressA];
//end
//end 
////port B
//always @ ( posedge ClockB )
//begin
//if(ResetB)
//QB <= 8'd0;
//else if(ClockEnB)begin
//	if(WrB)
//    block_ramB[AddressB] <= DataInB;
//	else	
//		QB <= block_ramB[AddressB];
//end
//end 
//
//endmodule

//`timescale 1ns / 1fs
module ebr_buffer
(
    input wire [7:0] DataInA,
    input wire [7:0] DataInB,
    input wire [10:0] AddressA,
    input wire [10:0] AddressB,
    input wire ClockA,
    input wire ClockB,
    input wire ClockEnA,
    input wire ClockEnB,
    input wire WrA,
    input wire WrB,
    input wire ResetA,
    input wire ResetB,
   // input disp,
    output wire [7:0] QA,
    output wire [7:0] QB
	  
);
	// Declare the RAM variable
	reg [7:0] ram[0:2047];
	
	reg [7:0] q_a, q_b;
	
	assign QA = q_a;
	assign QB = q_b;
	
	// Port A
	always @ (posedge ClockA)
	begin
	if(ClockEnA)
	begin
		if (WrA) 
		begin
			ram[AddressA] <= DataInA;
			q_a <= DataInA;
		end
		else 
		begin
			q_a <= ram[AddressA];
		end
	end
	end
	
	// Port B
	always @ (posedge ClockB)
	begin
	if (ClockEnB)
	begin
	if (WrB)
		begin
			ram[AddressB] <= DataInB;
			q_b <= DataInB;
		end
		else
		begin
			q_b <= ram[AddressB];
		end
	end
	end
	
	/*`ifdef DEBUG_RAM
	always @ (posedge disp)
	begin: named
	  // integer i;
	  if (disp)
	    begin
	      for(int i=0; i<10; i=i+1)
	      $display ("mem[%0d] = %0d", i, ram[i]);
	      
	      for(int i=51; i<68; i=i+1)
	      $display ("mem[%0d] = %0d", i, ram[i]);
		  
		    for (int i=2040; i<2048; i=i+1)
		    $display ("mem[%0d] = %0d", i, ram[i]);
	    end
	end
	`endif*/
	      
	
endmodule

