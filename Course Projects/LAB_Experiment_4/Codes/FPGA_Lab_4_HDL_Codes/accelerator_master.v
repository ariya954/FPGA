module AVM_AVALONMASTER_MAGNITUDE #
(
  // you can add parameters here
  // you can change these parameters
  parameter integer AVM_AVALONMASTER_DATA_WIDTH = 32,
  parameter integer AVM_AVALONMASTER_ADDRESS_WIDTH = 32
)
(
  // user ports begin

  input wire [AVM_AVALONMASTER_DATA_WIDTH - 1 : 0] slave_register0,
  input wire [AVM_AVALONMASTER_DATA_WIDTH - 1 : 0] slave_register1,
  input wire [AVM_AVALONMASTER_DATA_WIDTH - 1 : 0] slave_register2,
  input wire [AVM_AVALONMASTER_DATA_WIDTH - 1 : 0] slave_register3,

  // these are just some example ports. you can change them all
  input wire START,
  output wire DONE,

  // user ports end
  // dont change these ports
  input wire CSI_CLOCK_CLK,
  input wire CSI_CLOCK_RESET_N,
  output wire [AVM_AVALONMASTER_ADDRESS_WIDTH - 1:0] AVM_AVALONMASTER_ADDRESS,
  input wire AVM_AVALONMASTER_WAITREQUEST,
  output wire AVM_AVALONMASTER_READ,
  output wire AVM_AVALONMASTER_WRITE,
  input wire [AVM_AVALONMASTER_DATA_WIDTH - 1:0] AVM_AVALONMASTER_READDATA,
  output wire [AVM_AVALONMASTER_DATA_WIDTH - 1:0] AVM_AVALONMASTER_WRITEDATA
);

  // output wires and registers
  // you can change name and type of these ports
  reg done;

  reg [AVM_AVALONMASTER_ADDRESS_WIDTH - 1:0] address, read_address, write_address;
  reg read;
  reg write;
  reg [AVM_AVALONMASTER_DATA_WIDTH - 1:0] writedata;

  reg [(2 * AVM_AVALONMASTER_ADDRESS_WIDTH) - 1 : 0]Sum;
  reg [AVM_AVALONMASTER_DATA_WIDTH - 1:0]average;
  reg [18 : 0]Size_Counter;
  reg [10 : 0]Num_Counter;
  
  wire co_Size_Counter, co_Num_Counter;
  wire [AVM_AVALONMASTER_ADDRESS_WIDTH - 1 : 0] Right_Addr, Left_Addr, Out_Addr;
  wire [18 : 0]Size;
  wire [10 : 0]Num;

  assign Size = slave_register0[30 : 12];
  assign Num = slave_register0[11 : 1];
  assign Right_Addr = slave_register1;
  assign Left_Addr = slave_register2;
  assign Out_Addr = slave_register3;

  // I/O assignment
  // never directly send values to output
  assign DONE = done;
  assign AVM_AVALONMASTER_ADDRESS = address;
  assign AVM_AVALONMASTER_READ = read;
  assign AVM_AVALONMASTER_WRITE = write;
  assign AVM_AVALONMASTER_WRITEDATA = writedata;


  /****************************************************************************
  * all main function must be here or in main module. you MUST NOT use control
  * interface for the main operation and only can import and export some wires
  * from/to it
  ****************************************************************************/

  // user logic begin
  always @(posedge CSI_CLOCK_CLK)
  begin
    if(CSI_CLOCK_RESET_N == 0)
    begin
      done <= 0;
    end
    else
    begin
      done <= co_Num_Counter;
    end
  end

  reg[1 : 0] ns, ps;
  parameter[1 : 0] Idle = 2'b00, Init = 2'b01, Calc = 2'b10, Ready = 2'b11;

  always @(Size_Counter, Num_Counter, START, ps) begin
     {read, write} = 2'b0;
     case(ps)
       Idle:  begin ns = START ? Init : Idle; Num_Counter = 0; read_address = Right_Addr; write_address = Out_Addr; end
       Init:  begin ns = Calc; Sum = 0; Size_Counter = 0; end
       Calc: begin ns = co_Size_Counter ? Ready : Calc; read = 1; address = read_address; end
       Ready:  begin ns = co_Num_Counter ? Idle : Init; write = 1; address = write_address; end
       default: begin ns = Idle; end
     endcase
  end

  always @(posedge CSI_CLOCK_CLK, posedge CSI_CLOCK_RESET_N) begin

     if((ps == Calc) & (~AVM_AVALONMASTER_WAITREQUEST)) begin
       Size_Counter = Size_Counter + 1;
       Sum = Sum + AVM_AVALONMASTER_READDATA;
       read_address = read_address + 4;
     end
     
     if((ps == Ready) & (~AVM_AVALONMASTER_WAITREQUEST)) begin
       Num_Counter = Num_Counter + 1;
       write_address =  write_address + 4; 
     end

     if(CSI_CLOCK_RESET_N == 0)
       ps <= 0;
     else begin
       ps <= ns;
     end

  end

  assign writedata = (Sum / Size);
  assign co_Size_Counter = (Size_Counter >= Size) ? 1 : 0;
  assign co_Num_Counter = (Num_Counter >= Num) ? 1 : 0;

  // user logic end

endmodule
