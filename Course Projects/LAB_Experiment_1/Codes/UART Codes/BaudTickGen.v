module BaudTickGen(
    input clk, enable,
    output reg tick  // generate a tick at the specified baud rate * oversampling
);
parameter ClkFrequency = 50000000;
parameter Baud = 115200;
parameter Oversampling = 1;
reg [24:0] count = 0;
reg [24:0] top;

reg BaudTickGen_state = 0;

always @ (posedge clk) begin
       top =( (ClkFrequency / Baud) /Oversampling);
       tick = 1'b0;
       case(BaudTickGen_state)
          1'b0: if(enable) BaudTickGen_state <= 1'b1;
          1'b1: 
          	if(count == top) 
		    {tick, count, BaudTickGen_state} <= {1'b1, 26'b0};
	        else count = count + 1'b1; 
            
          default: BaudTickGen_state <= 1'b0;
       endcase  

end

endmodule

