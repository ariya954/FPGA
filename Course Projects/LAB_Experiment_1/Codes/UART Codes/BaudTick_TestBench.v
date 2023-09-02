`timescale 1ns/1ns

module BaudTick_Test_Bench();

wire tick;
reg clk, enable;

BaudTickGen Baud_Tick_Gen(clk, enable, tick); 

always #10 clk = ~clk;

initial begin

clk = 0;
#20 enable = 1;
#40 enable = 0;

#20000 $stop;

end

endmodule