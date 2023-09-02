module check_if_Calc_state_of_CU_works_correctly(clk, Filter_coefficeint_select, output_valid);
	parameter LENGTH = 8;
	input [LENGTH - 1 : 0]Filter_coefficeint_select;
	input clk, output_valid;

property pr;
&Filter_coefficeint_select |-> ##1 $rose(output_valid);
endproperty

Counting_coefficients_to_make_the_correct_output: assert property(@(posedge clk) (pr)) else $display("Filter coefficients counter reached the end but output valid didn't rise");

endmodule