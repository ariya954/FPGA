module FIR_Module_DataPath(clk, reset, RxD, TxD_start, input_valid, Load_FIR_In_LSB, Load_FIR_In_MSB, TxD_data_select, Load_FIR_OUT, output_valid, RxD_data_ready, TxD, TxD_busy);
	input clk, reset, RxD, TxD_start, input_valid, Load_FIR_In_LSB, Load_FIR_In_MSB, TxD_data_select, Load_FIR_OUT;
	output output_valid, RxD_data_ready, TxD, TxD_busy;

wire [7 : 0]RxD_data, TxD_data, LSB_FIR_Out, MSB_FIR_Out;
wire [15 : 0]FIR_input;
wire [37 : 0]FIR_output;

UART uart(.clk(clk), .RxD(RxD), .TxD_start(TxD_start), .TxD_data(TxD_data), .RxD_data_ready(RxD_data_ready), .RxD_data(RxD_data), .TxD(TxD), .TxD_busy(TxD_busy));

Register_D_Flip_Flop FIR_In_LSB(clk, reset, Load_FIR_In_LSB, RxD_data, FIR_input[7 : 0]);
Register_D_Flip_Flop FIR_In_MSB(clk, reset, Load_FIR_In_MSB, RxD_data, FIR_input[15 : 8]);

//FIR_LENGTH = 64
//FIR_INPUT_WIDTH = 16
//FIR_OUTPUT_WIDTH = 38
FIR_Filter #(64, 16, 38) FIR(.clk(clk), .reset(reset), .FIR_input(FIR_input), .input_valid(input_valid), .FIR_output(FIR_output), .output_valid(output_valid));

Register_D_Flip_Flop FIR_Out_LSB(clk, reset, Load_FIR_OUT, FIR_output[7 : 0], LSB_FIR_Out);
Register_D_Flip_Flop FIR_Out_MSB(clk, reset, Load_FIR_OUT, FIR_output[15 : 8], MSB_FIR_Out);

assign TxD_data = TxD_data_select ? MSB_FIR_Out: LSB_FIR_Out;

endmodule