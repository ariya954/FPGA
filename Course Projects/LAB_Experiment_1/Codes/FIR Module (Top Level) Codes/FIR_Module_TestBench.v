`timescale 1ns/1ns

module FIR_Module_Test_Bench();

wire RxD, TxD, Transmission_busy;
reg clk, reset, Transmission_start;
reg  [7:0] Transmission_data;

reg [16 - 1 : 0] FIR_input;
reg [16 - 1 : 0] FIR_inputs [0 : 1000];
 
async_transmitter Transmitter(.clk(clk), .TxD_start(Transmission_start), .TxD_data(Transmission_data), .TxD(RxD), .TxD_busy(Transmission_busy));
FIR_Module_Top FIR(.CLOCK_50(clk), .KEY(reset), .UART_RXD(RxD), .UART_TXD(TxD));

always #10 clk = ~clk;

initial
    begin  
    $readmemb("inputs.txt", FIR_inputs);   
end

integer i;

initial begin

clk = 0; reset = 1;
#20 reset = 0;
for(i = 0; i < 100; i = i + 1)
	begin
             FIR_input = FIR_inputs[i];
	     Transmission_data = FIR_input[15 : 8];

	     #100000 Transmission_start = 0;
	     #20 Transmission_start = 1;
	     #400 Transmission_start = 0;

	     #100000 Transmission_start = 0; Transmission_data = FIR_input[7 : 0];
	     #20 Transmission_start = 1;
	     #400 Transmission_start = 0; 

	     #100000;

	end

$stop;

end

endmodule
