module check_if_Output_Ready_state_of_CU_works_correctly(clk, output_valid, shift_enable);
	input clk, output_valid, shift_enable;

property pr;
$rose(output_valid) |-> $rose(shift_enable);
endproperty

Enable_shift_to_shift_the_values_in_shift_register: assert property(@(posedge clk) (pr)) else $display("output valid rose but shift didn't enabled to shift values in shift register");

endmodule