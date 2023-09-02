module FIR_Module_CU(clk, reset, RxD_data_ready, output_valid, TxD_busy, Load_FIR_In_LSB, Load_FIR_In_MSB, input_valid, Load_FIR_OUT, TxD_start, TxD_data_select);
	input clk, reset, RxD_data_ready, output_valid, TxD_busy;
	output reg Load_FIR_In_LSB, Load_FIR_In_MSB, input_valid, Load_FIR_OUT, TxD_start, TxD_data_select;

reg[2 : 0] ns, ps;
parameter[2 : 0] Receive_input_MSB = 3'b000, Receive_input_LSB = 3'b001, Valid_FIR_input_and_start_calculation = 3'b010, Calc = 3'b011, Load_FIR_output_and_start_sending = 3'b100, Send_output_MSB = 3'b101, Send_output_LSB = 3'b110;

always @(RxD_data_ready, output_valid, TxD_busy) begin
   {Load_FIR_In_LSB, Load_FIR_In_MSB, input_valid, Load_FIR_OUT, TxD_start} = 5'b0;
   case(ps)
     Receive_input_MSB:  begin ns = RxD_data_ready ? Receive_input_LSB : Receive_input_MSB; Load_FIR_In_MSB = RxD_data_ready ? 1 : 0; end
     Receive_input_LSB:  begin ns = RxD_data_ready ? Valid_FIR_input_and_start_calculation : Receive_input_LSB; Load_FIR_In_LSB = RxD_data_ready ? 1 : 0; end
     Valid_FIR_input_and_start_calculation: begin ns = Calc; input_valid = 1; end
     Calc:  begin ns = output_valid ? Load_FIR_output_and_start_sending : Calc; Load_FIR_OUT = output_valid ? 1 : 0; end
     Load_FIR_output_and_start_sending: begin ns = Send_output_MSB; TxD_start = 1; TxD_data_select = 1; end
     Send_output_MSB: begin ns = TxD_busy ? Send_output_MSB : Send_output_LSB; TxD_start = TxD_busy ? 0 : 1; TxD_data_select = TxD_busy ? 1 : 0; end
     Send_output_LSB: begin ns = TxD_busy ? Send_output_LSB : Receive_input_MSB; end
     default: begin ns = Receive_input_MSB; TxD_data_select = 0; end
   endcase
end

always @(posedge clk, posedge reset) begin

   if(reset)
     ps <= 0;
   else begin
     ps <= ns;
   end

end

endmodule