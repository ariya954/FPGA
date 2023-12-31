module ACCELERATOR_CTRL #
(
  // you can add parameters here
  // you can change these parameters

  // control interface parameters
  parameter integer avs_avalonslave_data_width = 32,
  parameter integer avs_avalonslave_address_width = 4,

  // control interface parameters
  parameter integer avm_avalonmaster_data_width = 32,
  parameter integer avm_avalonmaster_address_width = 32
)
(
  // user ports begin

  // user ports end
  // dont change these ports

  // clock and reset
  input wire csi_clock_clk,
  input wire csi_clock_reset_n,

  // control interface ports
  input wire [avs_avalonslave_address_width - 1:0] avs_avalonslave_address,
  output wire avs_avalonslave_waitrequest,
  input wire avs_avalonslave_read,
  input wire avs_avalonslave_write,
  output wire [avs_avalonslave_data_width - 1:0] avs_avalonslave_readdata,
  input wire [avs_avalonslave_data_width - 1:0] avs_avalonslave_writedata,

  // magnitude interface ports
  output wire [avm_avalonmaster_address_width - 1:0] avm_avalonmaster_address,
  input wire avm_avalonmaster_waitrequest,
  output wire avm_avalonmaster_read,
  output wire avm_avalonmaster_write,
  input wire [avm_avalonmaster_data_width - 1:0] avm_avalonmaster_readdata,
  output wire [avm_avalonmaster_data_width - 1:0] avm_avalonmaster_writedata
);

// define your extra ports as wire here
wire start;
wire done;

wire [avs_avalonslave_data_width - 1 : 0] Config_Reg, Right_Addr, Left_Addr, Out_Addr;

// control interface instanciation
AVS_AVALONSLAVE #
(
  // you can add parameters here
  // you can change these parameters
  .AVS_AVALONSLAVE_DATA_WIDTH(avs_avalonslave_data_width),
  .AVS_AVALONSLAVE_ADDRESS_WIDTH(avs_avalonslave_address_width)
) AVS_AVALONSLAVE_INST // instance  of module must be here
(
  // user ports begin
  .START(start),
  .DONE(done),
  // user ports end
  // dont change these ports
  .CSI_CLOCK_CLK(csi_clock_clk),
  .CSI_CLOCK_RESET_N(csi_clock_reset_n),
  .AVS_AVALONSLAVE_ADDRESS(avs_avalonslave_address),
  .AVS_AVALONSLAVE_WAITREQUEST(avs_avalonslave_waitrequest),
  .AVS_AVALONSLAVE_READ(avs_avalonslave_read),
  .AVS_AVALONSLAVE_WRITE(avs_avalonslave_write),
  .AVS_AVALONSLAVE_READDATA(avs_avalonslave_readdata),
  .AVS_AVALONSLAVE_WRITEDATA(avs_avalonslave_writedata),
  .slave_reister0(Config_Reg),
  .slave_reister1(Right_Addr),
  .slave_reister2(Left_Addr),
  .slave_reister3(Out_Addr)
);

// magnitude interface instanciation
AVM_AVALONMASTER_MAGNITUDE #
(
  // you can add parameters here
  // you can change these parameters
  .AVM_AVALONMASTER_DATA_WIDTH(avm_avalonmaster_data_width),
  .AVM_AVALONMASTER_ADDRESS_WIDTH(avm_avalonmaster_address_width)
) AVM_AVALONMASTER_MAGNITUDE_INST // instance  of module must be here
(
  // user ports begin

  .slave_reister0(Config_Reg),
  .slave_reister1(Right_Addr),
  .slave_reister2(Left_Addr),
  .slave_reister3(Out_Addr),

  .START(start),
  .DONE(done),
  // user ports end
  // dont change these ports
  .CSI_CLOCK_CLK(csi_clock_clk),
  .CSI_CLOCK_RESET_N(csi_clock_reset_n),
  .AVM_AVALONMASTER_ADDRESS(avm_avalonmaster_address),
  .AVM_AVALONMASTER_WAITREQUEST(avm_avalonmaster_waitrequest),
  .AVM_AVALONMASTER_READ(avm_avalonmaster_read),
  .AVM_AVALONMASTER_WRITE(avm_avalonmaster_write),
  .AVM_AVALONMASTER_READDATA(avm_avalonmaster_readdata),
  .AVM_AVALONMASTER_WRITEDATA(avm_avalonmaster_writedata)
);

endmodule
