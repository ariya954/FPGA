module check_if_CU_goes_from_Idle_state_to_Reset_FIR_output_state_correctly(clk, input_valid, reset_FIR_output);
	input clk, input_valid, reset_FIR_output;

property pr;
$rose(input_valid) |-> ##1 $rose(reset_FIR_output);
endproperty

Reseting_FIR_output: assert property(@(posedge clk) (pr)) else $display("input valid rose but FIR output didn't reset");

endmodule