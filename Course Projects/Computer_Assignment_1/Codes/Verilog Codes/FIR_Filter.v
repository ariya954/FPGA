module FIR_Filter(clk, reset, FIR_input, input_valid, FIR_output, output_valid);
	parameter LENGTH = 8;
	parameter WIDTH_OF_INPUT_DATA = 8;
        parameter WIDTH_OF_OUTPUT_DATA = 8;
	input clk, reset, input_valid;
	output output_valid;
	input [WIDTH_OF_INPUT_DATA - 1 : 0]FIR_input;
	output [WIDTH_OF_OUTPUT_DATA - 1 : 0]FIR_output;

wire Load_FIR_input, reset_FIR_output, shift_enable;
wire [LENGTH - 1 : 0]Filter_coefficeint_select;

FIR_DataPath #(LENGTH, WIDTH_OF_INPUT_DATA, WIDTH_OF_OUTPUT_DATA) Data_Path(.clk(clk), .reset(reset), .FIR_input(FIR_input), .Load_FIR_input(Load_FIR_input), .Filter_coefficeint_select(Filter_coefficeint_select), .shift_enable(shift_enable), .reset_FIR_output(reset_FIR_output), .FIR_output(FIR_output));
FIR_CU #(LENGTH) CU(.clk(clk), .reset(reset), .input_valid(input_valid), .Filter_coefficeint_select(Filter_coefficeint_select), .Load_FIR_input(Load_FIR_input), .reset_FIR_output(reset_FIR_output), .output_valid(output_valid), .shift_enable(shift_enable));

endmodule