module FIR_DataPath(clk, reset, FIR_input, Load_FIR_input, Filter_coefficeint_select, shift_enable, reset_FIR_output, FIR_output);
	input clk, reset, Load_FIR_input, shift_enable, reset_FIR_output;
	input  [7 : 0]FIR_input;
	input  [7 : 0]Filter_coefficeint_select;
	output [21 : 0]FIR_output;

reg signed [7 : 0] coefficeints [0 : 49];

wire [7 : 0] x [49 : 0];
wire [15 : 0] output_of_multiplier;
wire [21 : 0] sign_extended_output_of_multiplier;
wire [21 : 0] temporary_result;

genvar n;

generate

for(n = 50; n > 0; n = n - 1) begin : generate_shift_register
   if(n == 50)
      Register_D_Flip_Flop register(.clk(clk), .reset(reset), .load(Load_FIR_input), .D(FIR_input), .Q(x[n - 1]));
   else
      Register_D_Flip_Flop register(.clk(clk), .reset(reset), .load(shift_enable), .D(x[n]), .Q(x[n - 1])); 
end

endgenerate
Pipe_Line_Multiplier Mult(.A_input(x[49 - Filter_coefficeint_select]), .B_input(coefficeints[Filter_coefficeint_select]), .output_of_multiplier(output_of_multiplier));

Sign_Extension sign_extension(.input_data(output_of_multiplier), .output_data(sign_extended_output_of_multiplier));

Output_Register_D_Flip_Flop  temp_result(.clk(clk), .reset(reset_FIR_output), .load(1), .D(FIR_output + sign_extended_output_of_multiplier), .Q(FIR_output));


endmodule