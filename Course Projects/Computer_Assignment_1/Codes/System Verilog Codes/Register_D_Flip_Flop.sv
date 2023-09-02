module Register_D_Flip_Flop(clk, reset, load, D, Q);
	parameter WIDTH = 8;
	input clk, reset, load;
	input [WIDTH - 1 : 0]D;
	output reg [WIDTH - 1 : 0]Q;

always @(posedge clk, posedge reset)begin
   if(reset)
      Q <= 0;
   else begin
      if(load)
         Q <= D;
   end
end

endmodule