module Register_D_Flip_Flop(clk, reset, load, D, Q);
	input clk, reset, load;
	input [15 : 0]D;
	output reg [15 : 0]Q;

always @(posedge clk, posedge reset)begin
   if(reset)
      Q <= 0;
   else begin
      if(load)
         Q <= D;
   end
end

endmodule
