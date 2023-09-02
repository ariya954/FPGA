module FIR_CU(clk, reset, input_valid, Filter_coefficeint_select, Load_FIR_input, reset_FIR_output, output_valid, shift_enable);
	parameter LENGTH = 8;
	input clk, reset, input_valid;
	output reg Load_FIR_input, reset_FIR_output, output_valid, shift_enable;
	output reg [LENGTH - 1 : 0]Filter_coefficeint_select;

wire co_of_Filter_coefficeint_selector_counter;
reg[1 : 0] ns, ps;
parameter[1 : 0] Idle = 2'b00, Reset_FIR_output = 2'b01, Calc = 2'b10, Output_Ready = 2'b11;

always @(input_valid, ps, co_of_Filter_coefficeint_selector_counter) begin
   {Load_FIR_input, reset_FIR_output, output_valid, shift_enable} = 4'b0;
   case(ps)
     Idle:  begin ns = input_valid ? Reset_FIR_output : Idle; Load_FIR_input = input_valid ? 1 : 0; end
     Reset_FIR_output:  begin ns = Calc; reset_FIR_output = 1; end
     Calc:  begin ns = co_of_Filter_coefficeint_selector_counter ? Output_Ready : Calc; end
     Output_Ready: begin ns = Idle; output_valid = 1; shift_enable = 1; end
     default: begin ns = Idle; Filter_coefficeint_select = 8'b0; end
   endcase
end

always @(posedge clk, posedge reset) begin

   if(reset)
     ps <= 0;
   else begin
     ps <= ns;
   end

	if(clk)
     Filter_coefficeint_select <= (ps == Calc) ? Filter_coefficeint_select + 1 : 0;

end

assign co_of_Filter_coefficeint_selector_counter = (Filter_coefficeint_select >= LENGTH - 1) ? 1 : 0;

endmodule