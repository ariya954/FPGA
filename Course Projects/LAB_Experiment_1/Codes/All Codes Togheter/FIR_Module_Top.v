module FIR_Module_Top(CLOCK_50, KEY, UART_RXD, UART_TXD);

input CLOCK_50;
input [0:0] KEY;		//reset key

input UART_RXD;
output UART_TXD;

wire TxD_start, input_valid, Load_FIR_In_LSB, Load_FIR_In_MSB, TxD_data_select, Load_FIR_OUT, output_valid, RxD_data_ready, TxD_busy;

FIR_Module_DataPath DataPath(CLOCK_50, KEY, UART_RXD, TxD_start, input_valid, Load_FIR_In_LSB, Load_FIR_In_MSB, TxD_data_select, Load_FIR_OUT, output_valid, RxD_data_ready, UART_TXD, TxD_busy);
FIR_Module_CU CU(CLOCK_50, KEY, RxD_data_ready, output_valid, TxD_busy, Load_FIR_In_LSB, Load_FIR_In_MSB, input_valid, Load_FIR_OUT, TxD_start, TxD_data_select);

endmodule