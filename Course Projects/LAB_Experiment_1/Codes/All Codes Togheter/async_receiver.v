module async_receiver(
    input clk,
    input RxD,
    output reg RxD_data_ready = 0,
    output reg [7:0] RxD_data = 0  // data received, valid only (for one clock cycle) when RxD_data_ready is asserted
);

parameter ClkFrequency = 50000000;
parameter Baud = 115200;
parameter Oversampling = 4;	// needs to be a power of 2

wire RxDTick;
BaudTickGen #(ClkFrequency, Baud, Oversampling) tickgen(.clk(clk), .enable(1), .tick(RxDTick));

reg TxDTick, received_data;
reg [3:0] RxD_state = 0;
reg [1:0] over_sampling_state, sampled_data = 0;

always @(posedge TxDTick)
begin
        RxD_data_ready = 0;
	case(RxD_state)
        4'b0000: if(~received_data) RxD_state <= 4'b0001;  // start bit
        4'b0001: begin RxD_state <= 4'b0010; RxD_data[0] <= received_data; end // bit 0
        4'b0010: begin RxD_state <= 4'b0011; RxD_data[1] <= received_data; end // bit 1
        4'b0011: begin RxD_state <= 4'b0100; RxD_data[2] <= received_data; end // bit 2
        4'b0100: begin RxD_state <= 4'b0101; RxD_data[3] <= received_data; end // bit 3
        4'b0101: begin RxD_state <= 4'b0110; RxD_data[4] <= received_data; end // bit 4
        4'b0110: begin RxD_state <= 4'b0111; RxD_data[5] <= received_data; end // bit 5
        4'b0111: begin RxD_state <= 4'b1000; RxD_data[6] <= received_data; end // bit 6
        4'b1000: begin RxD_state <= 4'b1001; RxD_data[7] <= received_data; end // bit 7
        4'b1001: RxD_state <= 4'b1010;  // stop1
        4'b1010: begin RxD_state <= 4'b0000;  RxD_data_ready <= 1; end // ready
        default: RxD_state <= 4'b0000;
     endcase  
end

always @(posedge clk)
begin
	TxDTick = 0;
	case(over_sampling_state)
        2'b00: if(RxDTick) over_sampling_state <= 2'b01;
        2'b01: if(RxDTick) begin over_sampling_state <= 2'b10; end
        2'b10: if(RxDTick) begin over_sampling_state <= 2'b11; sampled_data[1] <= RxD; end
        2'b11: if(RxDTick) begin over_sampling_state <= 2'b00; TxDTick = 1; received_data = sampled_data[1]; end
        default: if(RxDTick) over_sampling_state <= 2'b00;
     endcase  
end


endmodule