`timescale 1ns/1ns

module UART_Test_Bench();

wire RxD_data_ready, RxD, TxD, Transmission_busy, TxD_busy;
reg clk, Transmission_start, TxD_start;
reg  [7:0] Transmission_data;
 
async_transmitter Transmitter(.clk(clk), .TxD_start(Transmission_start), .TxD_data(Transmission_data), .TxD(RxD), .TxD_busy(Transmission_busy));
UART_Test uart(RxD_data_ready, clk, RxD, TxD_start, TxD, TxD_busy);

always #10 clk = ~clk;

initial begin

clk = 0; Transmission_data = 8'b10010111; TxD_start = 0;
#1000 Transmission_start = 0;
#20 Transmission_start = 1;
#40 Transmission_start = 0;

#100000 TxD_start = 1;
#40 TxD_start = 0;
#100000 Transmission_data = 8'b10000001;

#1000 Transmission_start = 0;
#20 Transmission_start = 1;
#40 Transmission_start = 0;

#100000 TxD_start = 1;
#40 TxD_start = 0;
#100000 $stop;

end

endmodule
