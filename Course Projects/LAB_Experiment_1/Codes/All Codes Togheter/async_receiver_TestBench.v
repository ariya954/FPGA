`timescale 1ns/1ns

module async_receiver_Test_Bench();
	parameter ClkFrequency = 50000000;
	parameter Baud = 115200;
	parameter Oversampling = 4;	// needs to be a power of 2

wire TxD, TxD_busy;
wire [7 : 0]RxD_data;
reg clk, TxD_start;
reg  [7:0] TxD_data;

async_receiver #(ClkFrequency, Baud, Oversampling) Receiver(.clk(clk), .RxD(TxD), .RxD_data_ready(RxD_data_ready), .RxD_data(RxD_data));
async_transmitter Transmitter(.clk(clk), .TxD_start(TxD_start), .TxD_data(TxD_data), .TxD(TxD), .TxD_busy(TxD_busy));
always #10 clk = ~clk;

initial begin

clk = 0; TxD_data = 8'b10010101;
#1000 TxD_start = 0;
#20 TxD_start = 1;
#40 TxD_start = 0;

#1000000 $stop;

end

endmodule
