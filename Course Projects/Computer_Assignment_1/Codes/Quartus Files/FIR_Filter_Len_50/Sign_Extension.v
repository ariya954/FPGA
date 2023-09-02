module Sign_Extension(input_data, output_data);
	input  [15 : 0]input_data;
	output [21 : 0]output_data;
 
assign output_data = {input_data[15], input_data[15], input_data[15], input_data[15], input_data[15], input_data[15], input_data};

endmodule
