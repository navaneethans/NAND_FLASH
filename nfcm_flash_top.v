// --------------------------------------------------------------------
`timescale 1 ns / 1 ps

module nfcm_flash_top(

								 input clk,
								 input rst,
								 output tx,
								 input  rx,
								 inout [7:0] DIO,
								 output CLE,// -- CLE
								 output ALE,//  -- ALE
								 output WE_n,// -- ~WE
								 output RE_n, //-- ~RE
								 output CE_n, //-- ~CE
								 input  R_nB//-- R/~B				
							);

 reg BF_sel;
 reg [10:0] BF_ad;
 reg [7:0] BF_din;
 reg BF_we;
 reg [15:0] RWA; //-- row addr
 wire [7:0] BF_dou;
 wire PErr; // -- progr err
 wire EErr; // -- erase err
 wire RErr;
 reg [2:0] nfc_cmd; // -- command see below
 reg nfc_strt;//  -- pos edge (pulse) to start
 wire nfc_done; //  -- operation finished if '1'
 wire [11:0]dio_cnt;
 reg [2:0]Flash_func;
 
 reg file_write_done;
 reg file_read_done;
 reg [5:0]page_address;
 reg [9:0]block_address;
 reg [3:0]step;
 reg flash_operation_en;
 reg [7:0]flash_data_out;
 
   reg [63:0]debug_data;
	wire [63:0]debug_set;
	wire [7:0]data;
	wire debug_sent = (debug_data == debug_set) ? 1'b1 : 1'b0;
	reg [7:0]ascii_data;
	reg [7:0]ascii1;
	reg [7:0]ascii2;
	reg [7:0]ascii3;
// Instantiation of the clock_source

wire clk_25_flash;
wire clk_100_chipscope;

clk_40 clk_source
   (// Clock in ports
    .CLK_IN1(clk),      // IN
    // Clock out ports
    .CLK_OUT1(clk_25_flash),     // OUT
    .CLK_OUT2(clk_100_chipscope));    // OUT

/// Instantiation of the nfcm_top
nfcm_top nfcm(
 .DIO(DIO),
 .CLE(CLE),
 .ALE(ALE),
 .WE_n(WE_n),
 .RE_n(RE_n),
 .CE_n(CE_n),
 .R_nB(R_nB),
 .WP_n(WP_n),

 .CLK(clk_25_flash),
 .RES(rst),

 .BF_sel(BF_sel),//
 .BF_ad (BF_ad), //
 .BF_din(BF_din),//
 .BF_we (BF_we), // 
 .RWA   (RWA), //

 .BF_dou(BF_dou),
 .PErr(PErr), 
 .EErr(EErr), 
 .RErr(RErr),
      
 .nfc_cmd (nfc_cmd), //
 .nfc_strt(nfc_strt),  //
 .nfc_done(nfc_done),
 //// Debugg signals
 .CntOut(dio_cnt)
);

/* Read ID, Reset cycle, Erase block, Read page, Write page */////
//////////////////////////////////////////////////////////////////
reg [7:0]page_mem[2047:0];
initial
	$readmemh("../input_hexfile/page_data.hex",page_mem);   
/////////////////////////////////////////////////////////////////
integer i;
always@(posedge clk_25_flash) 
begin
	if(rst)begin
		BF_sel<=1'b0;                   
		BF_ad<=12'd0;            
		BF_din<=8'd0;            
		BF_we<=1'b0;                   
		RWA<=16'd0; 
		i <= 32'd0;
		nfc_cmd<=3'b111;
		nfc_strt<=1'b0;
		Flash_func <= 3'b010;	
		step <= 4'd0;	
		flash_operation_en<=1'b0;
		page_address <= 6'd0;
		block_address <= 10'd0;	
		file_write_done <= 1'b0;
		file_read_done <= 1'b0;
		flash_data_out <= 8'd0;
		ascii_data <= 8'd0;
			ascii1 <= 8'd0;
			ascii2 <= 8'd0;
			ascii3 <= 8'd0;
	
	end
	else if(step == 0) begin
				step <= 1;
				Flash_func <= data[2:0]; //
				page_address <= 6'd0;
				block_address <= 10'd0;
				flash_operation_en <= 1'b1;
	end
	else if(flash_operation_en) begin
	case (Flash_func)
	
	3'b001: begin						/* Page Program/Write page */
						
					if (step == 1) begin
					 RWA      <= {block_address,page_address};  //Flash_address
					 nfc_cmd  <= 3'b001;
					 BF_sel   <= 1'b1;
					 nfc_strt <= 1'b1;
					 i			<=	0;
					 step <= 2;
					end
					else if(step == 2)begin
					 nfc_strt <= 1'b0;
					 BF_ad <= 0; 
					 step <= 3 ;
					end
					else if(step == 3) begin
						if(i < 2048) begin
								BF_we <= 1'b1;
								BF_din <= page_mem[i];
								BF_ad <= i; 
								i <= i +1;
								step <= 3;
								debug_data <= "FPWRT..\n";
						end
						else begin
								BF_we <= 1'b0;	
								if(nfc_done) 
									step <= 4;
							end
					end
				  else if(step == 4) begin
						nfc_cmd <= 3'b111;
						BF_sel <= 1'b0;
						file_write_done <= 1'b1;
						flash_operation_en <= 1'b1;
						debug_data <= "FPWRTDN\n";
				  end
				 
				end
	3'b010: begin					/* Read Page */
	
						if(step == 1)begin
							RWA      <= {block_address,page_address};//Flash_address 
							nfc_cmd  <= 3'b010;
							BF_sel   <= 1'b1;
							BF_we    <= 1'b0;
							BF_ad    <= 12'd0;
							nfc_strt <= 1'b1;
							step <= 2;
							i <= 0;
						end
						else if(step == 2)begin
							nfc_strt <= 1'b0;
							step <= 3;
						end
						else if(step == 3)begin
							if(nfc_done)begin
								nfc_cmd <= 3'b111;
								step <= 4;
							end
						end
						else if(step == 4) begin
							if( i < 2048) begin
									flash_data_out <= BF_dou;
									BF_ad <= i;
									i <= i + 1;
									step <= 4;
									debug_data <= "FPREAD\n";
							end
							else begin
									i <= 0;
									BF_ad <= 0;
									file_read_done <= 1'b1;
									flash_operation_en <= 1'b0;
									debug_data <= "FPREADN\n";
							end
						end						
			  end
	
	3'b011 : begin						/*	Reset */
					
				 if(step == 1)begin
						nfc_cmd<=3'b011;
						nfc_strt<=1'b1;
						step <= 2;
					end
					else if(step == 2)begin
						nfc_strt <= 1'b0;
						if(nfc_done)
						step <= 3;
					end
					else if(step == 3) begin
						nfc_cmd <= 3'b111;
						flash_operation_en <= 1'b1;
						step <= 4;
						 debug_data <= "FLASRST\n";
					end
				end
	3'b100: begin						/*	Erase Block */
					
					if(step == 1) begin                
						RWA<= {block_address,page_address}; 
						nfc_cmd<=3'b100;
						nfc_strt<=1'b1;
						step <= 2;
					end
					else if(step == 2)begin
						nfc_strt <= 1'b0;
						step <= 3;
					end
					else if(step == 3)begin
						if(nfc_done)
							step <= 4;
					end
					else if(step == 4) begin
						nfc_cmd <= 3'b111;
						flash_operation_en <= 1'b1;
						step <= 5;
					end
					else if(step == 5) begin
						if(block_address < 1023)begin
							block_address <= block_address + 1;
							step <= 1;
							ascii1 <= 	(block_address/1000 )+8'd48;
							ascii2 <= 	((block_address%1000)/100)+8'd48;
							ascii3 <=   ((block_address % 100)/10)+8'd48;
							ascii_data <= ((block_address % 10)+8'd48);						
							debug_data <= {"ERA",ascii1,ascii2,ascii3,ascii_data,"\n"};
						end
						else begin
							debug_data <= "ERADONE\n";
							//step <= 0;					
					   end
					end
				end
	3'b101: begin						/* Read ID */
					BF_sel<=1'b1;                   
					BF_ad<=0;            
					BF_din<=0;            
					BF_we<=1'b0;                   
					RWA<= 16'h0000; 
					nfc_cmd<=3'b101;
					nfc_strt<=1'b1;
					if(nfc_done)
						debug_data <= {DIO,"READID\n"};
				end
	
	default :  nfc_cmd<= 3'b111;
	
	endcase
	end
end

//// -------------------------------------------------------------------- //
 debug_signal uart_uut(
		.debug_data(debug_data),
		.debug_set(debug_set),
		.clk(clk_25_flash), 
		.tx(tx),
		.rx(rx),
		.data(data)
    );                                     
                                                                        
// --------------------------------------------------------------------- //  
wire [35:0]CONTROL0;
wire [35:0]TRIG0;
assign TRIG0[7:0] = DIO;
assign TRIG0[8] = rst;
assign TRIG0[19:9]= dio_cnt;
//assign TRIG0[19] = CE_n;
assign TRIG0[27:20] = BF_ad;
//assign TRIG0[21] = ALE;
//assign TRIG0[22] = WE_n;
//assign TRIG0[23] = RE_n;
//assign TRIG0[24] = nfc_done;
//assign TRIG0[27:25] = Flash_func;
assign TRIG0[35:28] = BF_dou;

chip_debug icon_control (
    .CONTROL0(CONTROL0)
);

chip_ila trig_sig (
    .CONTROL(CONTROL0), // INOUT BUS [35:0]
    .CLK(clk_100_chipscope), // IN
    .TRIG0(TRIG0) // IN BUS [7:0]
    
);

endmodule

