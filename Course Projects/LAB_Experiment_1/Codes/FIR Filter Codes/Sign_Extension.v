module Sign_Extension(input_data, output_data);
	parameter WIDTH_OF_INPUT_DATA = 8;
        parameter WIDTH_OF_OUTPUT_DATA = 8;
	input  [WIDTH_OF_INPUT_DATA - 1 : 0]input_data;
	output [WIDTH_OF_OUTPUT_DATA - 1 : 0]output_data;

wire [(WIDTH_OF_OUTPUT_DATA - WIDTH_OF_INPUT_DATA) - 1 : 0] extension_of_sign_bit;

genvar i;

generate

for(i = 0; i < WIDTH_OF_OUTPUT_DATA - WIDTH_OF_INPUT_DATA; i = i + 1) begin : generate_extension_of_sign_bit
   assign extension_of_sign_bit[i] = input_data[WIDTH_OF_INPUT_DATA - 1];
end
endgenerate
 
assign output_data = {extension_of_sign_bit, input_data};

endmodule
