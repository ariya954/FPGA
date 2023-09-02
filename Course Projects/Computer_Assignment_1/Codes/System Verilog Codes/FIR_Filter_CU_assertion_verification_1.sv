module check_if_Idle_state_of_CU_works_correctly(clk, input_valid, Load_FIR_input);
	input clk, input_valid, Load_FIR_input;

property pr;
$rose(input_valid) |-> $rose(Load_FIR_input);
endproperty

Loading_FIR_input: assert property(@(posedge clk) (pr)) else $display("input valid rose but FIR input didn't Load");

endmodule