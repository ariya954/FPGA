module UART(clk, RxD, TxD_start, TxD_data, RxD_data_ready, RxD_data, TxD, TxD_busy, SW);
	input clk, RxD, TxD_start;
	input [7 : 0]TxD_data;
	output RxD_data_ready, TxD, TxD_busy;
	output [7 : 0]RxD_data;
	input [3:0] SW;
async_receiver Receiver(.clk(clk), .RxD(RxD), .RxD_data_ready(RxD_data_ready), .RxD_data(RxD_data));
async_transmitter Transmitter(.clk(clk), .TxD_start(TxD_start), .TxD_data(TxD_data), .TxD(TxD), .TxD_busy(TxD_busy));

endmodule