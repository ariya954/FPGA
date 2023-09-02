`timescale 1ns/1ns

module Transmitter_Test_Bench();

wire TxD, TxD_busy;
reg  clk, TxD_start;
reg  [7:0] TxD_data;

async_transmitter Transmitter(clk, TxD_start, TxD_data, TxD, TxD_busy); 

always #10 clk = ~clk;

initial begin

clk = 0; TxD_data = 8'b10010101;
#20 TxD_start = 1;
#40 TxD_start = 0;

#200000 $stop;

end

endmodule
