module FIR_DataPath(clk, reset, FIR_input, Load_FIR_input, Filter_coefficeint_select, shift_enable, reset_FIR_output, FIR_output);
	parameter LENGTH = 8;
	parameter WIDTH_OF_INPUT_DATA = 8;
        parameter WIDTH_OF_OUTPUT_DATA = 8;
	input clk, reset, Load_FIR_input, shift_enable, reset_FIR_output;
	input  [WIDTH_OF_INPUT_DATA - 1 : 0]FIR_input;
	input  [WIDTH_OF_INPUT_DATA - 1 : 0]Filter_coefficeint_select;
	output [WIDTH_OF_OUTPUT_DATA - 1 : 0]FIR_output;

wire [WIDTH_OF_INPUT_DATA - 1 : 0] coefficeints [0 : LENGTH - 1];

		assign coefficeints[0] = 16'b0000000001111001;
		assign coefficeints[1] = 16'b0000000001100000;
		assign coefficeints[2] = 16'b1111111111001010;
		assign coefficeints[3] = 16'b1111111011001010;
		assign coefficeints[4] = 16'b1111111000011101;
		assign coefficeints[5] = 16'b1111111001110101;
		assign coefficeints[6] = 16'b1111111110110001;
		assign coefficeints[7] = 16'b0000000011001010;
		assign coefficeints[8] = 16'b0000000010111100;
		assign coefficeints[9] = 16'b1111111110011110;
		assign coefficeints[10] = 16'b1111111010110000;
		assign coefficeints[11] = 16'b1111111100011110;
		assign coefficeints[12] = 16'b0000000010100011;
		assign coefficeints[13] = 16'b0000000110100010;
		assign coefficeints[14] = 16'b0000000011010101;
		assign coefficeints[15] = 16'b1111111011011110;
		assign coefficeints[16] = 16'b1111110111100011;
		assign coefficeints[17] = 16'b1111111101000101;
		assign coefficeints[18] = 16'b0000000111010100;
		assign coefficeints[19] = 16'b0000001010110011;
		assign coefficeints[20] = 16'b0000000001110100;
		assign coefficeints[21] = 16'b1111110100011100;
		assign coefficeints[22] = 16'b1111110010000010;
		assign coefficeints[23] = 16'b0000000000100000;
		assign coefficeints[24] = 16'b0000010010110000;
		assign coefficeints[25] = 16'b0000010010111111;
		assign coefficeints[26] = 16'b1111111010001101;
		assign coefficeints[27] = 16'b1111011101101001;
		assign coefficeints[28] = 16'b1111100001010101;
		assign coefficeints[29] = 16'b0000010111111001;
		assign coefficeints[30] = 16'b0001101100000001;
		assign coefficeints[31] = 16'b0010101011001000;
		assign coefficeints[32] = 16'b0010101011001000;
		assign coefficeints[33] = 16'b0001101100000001;
		assign coefficeints[34] = 16'b0000010111111001;
		assign coefficeints[35] = 16'b1111100001010101;
		assign coefficeints[36] = 16'b1111011101101001;
		assign coefficeints[37] = 16'b1111111010001101;
		assign coefficeints[38] = 16'b0000010010111111;
		assign coefficeints[39] = 16'b0000010010110000;
		assign coefficeints[40] = 16'b0000000000100000;
		assign coefficeints[41] = 16'b1111110010000010;
		assign coefficeints[42] = 16'b1111110100011100;
		assign coefficeints[43] = 16'b0000000001110100;
		assign coefficeints[44] = 16'b0000001010110011;
		assign coefficeints[45] = 16'b0000000111010100;
		assign coefficeints[46] = 16'b1111111101000101;
		assign coefficeints[47] = 16'b1111110111100011;
		assign coefficeints[48] = 16'b1111111011011110;
		assign coefficeints[49] = 16'b0000000011010101;
		assign coefficeints[50] = 16'b0000000110100010;
		assign coefficeints[51] = 16'b0000000010100011;
		assign coefficeints[52] = 16'b1111111100011110;
		assign coefficeints[53] = 16'b1111111010110000;
		assign coefficeints[54] = 16'b1111111110011110;
		assign coefficeints[55] = 16'b0000000010111100;
		assign coefficeints[56] = 16'b0000000011001010;
		assign coefficeints[57] = 16'b1111111110110001;
		assign coefficeints[58] = 16'b1111111001110101;
		assign coefficeints[59] = 16'b1111111000011101;
		assign coefficeints[60] = 16'b1111111011001010;
		assign coefficeints[61] = 16'b1111111111001010;
		assign coefficeints[62] = 16'b0000000001100000;
		assign coefficeints[63] = 16'b0000000001111001;

wire [WIDTH_OF_INPUT_DATA  - 1 : 0] x [LENGTH - 1 : 0];
wire [(2 * WIDTH_OF_INPUT_DATA) - 1 : 0] output_of_multiplier;
wire [WIDTH_OF_OUTPUT_DATA - 1 : 0] sign_extended_output_of_multiplier;
wire [WIDTH_OF_OUTPUT_DATA - 1 : 0] temporary_result;

genvar n;
generate
for(n = LENGTH; n > 0; n = n - 1) begin : generate_shift_register
   if(n == LENGTH)
      Register_D_Flip_Flop #(WIDTH_OF_INPUT_DATA) register(.clk(clk), .reset(reset), .load(Load_FIR_input), .D(FIR_input), .Q(x[n - 1]));
   else
      Register_D_Flip_Flop #(WIDTH_OF_INPUT_DATA) register(.clk(clk), .reset(reset), .load(shift_enable), .D(x[n]), .Q(x[n - 1])); 
end
endgenerate

Pipe_Line_Multiplier #(WIDTH_OF_INPUT_DATA) Mult(.A_input(x[LENGTH - 1 - Filter_coefficeint_select]), .B_input(coefficeints[Filter_coefficeint_select]), .output_of_multiplier(output_of_multiplier));

Sign_Extension #(2 * WIDTH_OF_INPUT_DATA, WIDTH_OF_OUTPUT_DATA) sign_extension(.input_data(output_of_multiplier), .output_data(sign_extended_output_of_multiplier));

Register_D_Flip_Flop #(WIDTH_OF_OUTPUT_DATA) temp_result(.clk(clk), .reset(reset_FIR_output), .load(1), .D(FIR_output + sign_extended_output_of_multiplier), .Q(FIR_output));


endmodule