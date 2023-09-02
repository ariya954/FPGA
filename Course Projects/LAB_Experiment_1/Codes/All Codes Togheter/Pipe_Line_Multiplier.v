module Pipe_Line_Multiplier(A_input, B_input, output_of_multiplier);
	parameter WIDTH = 8;
	input [WIDTH - 1 : 0]A_input, B_input;
	output [(2 * WIDTH) - 1 : 0]output_of_multiplier;

wire [WIDTH - 1 : 0]absolute_value_of_A_input, absolute_value_of_B_input, ArBr, ArBl, AlBr, AlBl, ArBl_plus_AlBr;
wire co_of_ArBl_plus_AlBr, co_of_first_adder, co_of_second_adder;
wire [(2 * WIDTH) - 1 : 0]absolute_value_of_output_of_multiplier;

assign absolute_value_of_A_input = A_input[WIDTH - 1] ? ~(A_input) + 1 : A_input;
assign absolute_value_of_B_input = B_input[WIDTH - 1] ? ~(B_input) + 1 : B_input;

assign ArBr = absolute_value_of_A_input[(WIDTH / 2) - 1 : 0] * absolute_value_of_B_input[(WIDTH / 2) - 1 : 0];
assign ArBl = absolute_value_of_A_input[(WIDTH / 2) - 1 : 0] * absolute_value_of_B_input[WIDTH - 1 : WIDTH / 2];
assign AlBr = absolute_value_of_A_input[WIDTH - 1 : WIDTH / 2] * absolute_value_of_B_input[(WIDTH / 2) - 1 : 0];
assign AlBl = absolute_value_of_A_input[WIDTH - 1 : WIDTH / 2] * absolute_value_of_B_input[WIDTH - 1 : WIDTH / 2];

assign {co_of_ArBl_plus_AlBr, ArBl_plus_AlBr} = ArBl + AlBr;

assign absolute_value_of_output_of_multiplier[(WIDTH / 2) - 1 : 0] = ArBr[(WIDTH / 2) - 1 : 0];
assign {co_of_first_adder, absolute_value_of_output_of_multiplier[WIDTH - 1 : WIDTH / 2]} = ArBl_plus_AlBr[(WIDTH / 2) - 1 : 0] + ArBr[WIDTH - 1 : WIDTH / 2];
assign {co_of_second_adder, absolute_value_of_output_of_multiplier[(3 * (WIDTH / 2)) - 1 : WIDTH]} = ArBl_plus_AlBr[WIDTH - 1 : WIDTH / 2] + AlBl[(WIDTH / 2) - 1 : 0] + co_of_first_adder;
assign absolute_value_of_output_of_multiplier[(2 * WIDTH) - 1 : 3 * (WIDTH / 2)] = AlBl[WIDTH - 1 : WIDTH / 2] + co_of_ArBl_plus_AlBr + co_of_second_adder;

assign output_of_multiplier = (A_input[WIDTH - 1] ^ B_input[WIDTH - 1]) ? ~(absolute_value_of_output_of_multiplier) + 1 : absolute_value_of_output_of_multiplier;

endmodule