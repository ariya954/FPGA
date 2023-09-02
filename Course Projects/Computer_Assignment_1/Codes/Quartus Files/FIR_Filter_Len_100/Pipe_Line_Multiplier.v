module Pipe_Line_Multiplier(A_input, B_input, output_of_multiplier);
	input [15 : 0]A_input, B_input;
	output [31 : 0]output_of_multiplier;

wire [15 : 0]absolute_value_of_A_input, absolute_value_of_B_input, ArBr, ArBl, AlBr, AlBl, ArBl_plus_AlBr;
wire co_of_ArBl_plus_AlBr, co_of_first_adder, co_of_second_adder;
wire [31 : 0]absolute_value_of_output_of_multiplier;

assign absolute_value_of_A_input = A_input[15] ? ~(A_input) + 1 : A_input;
assign absolute_value_of_B_input = B_input[15] ? ~(B_input) + 1 : B_input;

assign ArBr = absolute_value_of_A_input[7 : 0] * absolute_value_of_B_input[7 : 0];
assign ArBl = absolute_value_of_A_input[7 : 0] * absolute_value_of_B_input[15 : 8];
assign AlBr = absolute_value_of_A_input[15 : 8] * absolute_value_of_B_input[7 : 0];
assign AlBl = absolute_value_of_A_input[15 : 8] * absolute_value_of_B_input[15 : 8];

assign {co_of_ArBl_plus_AlBr, ArBl_plus_AlBr} = ArBl + AlBr;

assign absolute_value_of_output_of_multiplier[7 : 0] = ArBr[7 : 0];
assign {co_of_first_adder, absolute_value_of_output_of_multiplier[15 : 8]} = ArBl_plus_AlBr[7 : 0] + ArBr[15 : 8];
assign {co_of_second_adder, absolute_value_of_output_of_multiplier[23 : 16]} = ArBl_plus_AlBr[15 : 8] + AlBl[7 : 0] + co_of_first_adder;
assign absolute_value_of_output_of_multiplier[31 : 24] = AlBl[15 : 8] + co_of_ArBl_plus_AlBr + co_of_second_adder;

assign output_of_multiplier = (A_input[15] ^ B_input[15]) ? ~(absolute_value_of_output_of_multiplier) + 1 : absolute_value_of_output_of_multiplier;

endmodule