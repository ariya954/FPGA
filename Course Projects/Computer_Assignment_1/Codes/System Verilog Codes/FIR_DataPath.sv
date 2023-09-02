module FIR_DataPath(clk, reset, FIR_input, Load_FIR_input, Filter_coefficeint_select, shift_enable, reset_FIR_output, FIR_output);
	parameter LENGTH = 8;
	parameter WIDTH_OF_INPUT_DATA = 8;
        parameter WIDTH_OF_OUTPUT_DATA = 8;
	input clk, reset, Load_FIR_input, shift_enable, reset_FIR_output;
	input  [WIDTH_OF_INPUT_DATA - 1 : 0]FIR_input;
	input  [WIDTH_OF_INPUT_DATA - 1 : 0]Filter_coefficeint_select;
	output [WIDTH_OF_OUTPUT_DATA - 1 : 0]FIR_output;

reg signed [WIDTH_OF_INPUT_DATA - 1 : 0] coefficeints [0 : LENGTH - 1];

initial
	begin
		$readmemb("coeffs.txt", coefficeints);
	end

wire [WIDTH_OF_INPUT_DATA  - 1 : 0] x [LENGTH - 1 : 0];
wire [(2 * WIDTH_OF_INPUT_DATA) - 1 : 0] output_of_multiplier;
wire [WIDTH_OF_OUTPUT_DATA - 1 : 0] sign_extended_output_of_multiplier;
wire [WIDTH_OF_OUTPUT_DATA - 1 : 0] temporary_result;

genvar n;
generate
for(n = LENGTH; n > 0; n = n - 1) 
   if(n == LENGTH)
      Register_D_Flip_Flop #(WIDTH_OF_INPUT_DATA) register(.clk(clk), .reset(reset), .load(Load_FIR_input), .D(FIR_input), .Q(x[n - 1]));
   else
      Register_D_Flip_Flop #(WIDTH_OF_INPUT_DATA) register(.clk(clk), .reset(reset), .load(shift_enable), .D(x[n]), .Q(x[n - 1])); 
endgenerate

Pipe_Line_Multiplier #(WIDTH_OF_INPUT_DATA) Mult(.A_input(x[LENGTH - 1 - Filter_coefficeint_select]), .B_input(coefficeints[Filter_coefficeint_select]), .output_of_multiplier(output_of_multiplier));

Sign_Extension #(2 * WIDTH_OF_INPUT_DATA, WIDTH_OF_OUTPUT_DATA) sign_extension(.input_data(output_of_multiplier), .output_data(sign_extended_output_of_multiplier));

Register_D_Flip_Flop #(WIDTH_OF_OUTPUT_DATA) temp_result(.clk(clk), .reset(reset_FIR_output), .load(1), .D(FIR_output + sign_extended_output_of_multiplier), .Q(FIR_output));


endmodule