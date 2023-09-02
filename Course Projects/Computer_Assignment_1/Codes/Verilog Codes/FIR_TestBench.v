`timescale 1ns/1ns

module FIR_Test_Bench();
	parameter LENGTH = 64;
	parameter WIDTH_OF_INPUT_DATA = 16;
        parameter WIDTH_OF_OUTPUT_DATA = 38;
        parameter NUMBER_OF_INPUTS = 1000;

reg clk, reset, input_valid;
reg [WIDTH_OF_INPUT_DATA - 1 : 0] FIR_input;
reg [WIDTH_OF_INPUT_DATA - 1 : 0] FIR_inputs [0 : NUMBER_OF_INPUTS];
reg [WIDTH_OF_OUTPUT_DATA - 1 : 0] expected_outputs [0 : NUMBER_OF_INPUTS];
wire output_valid;
wire [WIDTH_OF_OUTPUT_DATA - 1 : 0]FIR_output;
integer i;

FIR_Filter #(LENGTH, WIDTH_OF_INPUT_DATA, WIDTH_OF_OUTPUT_DATA) FIR(.clk(clk), .reset(reset), .FIR_input(FIR_input), .input_valid(input_valid), .FIR_output(FIR_output), .output_valid(output_valid));

initial
    begin  
    $readmemb("inputs.txt", FIR_inputs);   
end

initial
    begin
    $readmemb("outputs.txt", expected_outputs);
end  

always #10 clk = ~clk;

initial begin

clk = 0; reset = 1; input_valid = 0;
#20 reset = 0;

for(i = 0; i < NUMBER_OF_INPUTS; i = i + 1)
	begin
             @(posedge clk);
             FIR_input = FIR_inputs[i];      
             input_valid = 1;
             #20 input_valid = 0;
             wait(output_valid == 1);
	end

$stop;

end

endmodule