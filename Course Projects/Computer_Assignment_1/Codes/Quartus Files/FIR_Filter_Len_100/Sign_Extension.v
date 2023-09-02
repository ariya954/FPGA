module Sign_Extension(input_data, output_data);
	input  [31 : 0]input_data;
	output [37 : 0]output_data;
 
assign output_data = {input_data[31], input_data[31], input_data[31], input_data[31], input_data[31], input_data[31], input_data};

endmodule
