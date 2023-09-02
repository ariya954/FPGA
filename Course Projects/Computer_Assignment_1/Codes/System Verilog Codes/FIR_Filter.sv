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

check_if_Idle_state_of_CU_works_correctly property_1(.clk(clk), .input_valid(input_valid), .Load_FIR_input(Load_FIR_input));
check_if_CU_goes_from_Idle_state_to_Reset_FIR_output_state_correctly property_2(.clk(clk), .input_valid(input_valid), .reset_FIR_output(reset_FIR_output));
check_if_Calc_state_of_CU_works_correctly #(LENGTH) property_3(.clk(clk), .Filter_coefficeint_select(Filter_coefficeint_select), .output_valid(output_valid));
check_if_Output_Ready_state_of_CU_works_correctly property_4(.clk(clk), .output_valid(output_valid), .shift_enable(shift_enable));

bind CU check_if_Idle_state_of_CU_works_correctly bind_property_1(.clk(clk), .input_valid(input_valid), .Load_FIR_input(Load_FIR_input));
bind CU check_if_CU_goes_from_Idle_state_to_Reset_FIR_output_state_correctly bind_property_2(.clk(clk), .input_valid(input_valid), .reset_FIR_output(reset_FIR_output));
bind CU check_if_Calc_state_of_CU_works_correctly bind_property_3(.clk(clk), .Filter_coefficeint_select(Filter_coefficeint_select), .output_valid(output_valid));
bind CU check_if_Output_Ready_state_of_CU_works_correctly bind_property_4(.clk(clk), .output_valid(output_valid), .shift_enable(shift_enable));

endmodule