`timescale 1ns/1ns

module SPI_tb;

  initial begin
    $dumpfile("SPI_tb.vcd");
    $dumpvars(0, SPI_tb);
  end

  reg         clk, rst, enable;
  reg  [31:0] data_out;
  reg  [7:0]  commands;
  reg  [23:0] Address;
  reg         MISO;              // driven by the testbench (slave)

  wire CS, SCLK, MOSI;

  SPI_Master uut (
    .clk(clk), .rst(rst), .enable(enable),
    .data_out(data_out), .commands(commands), .Address(Address),
    .CS(CS), .SCLK(SCLK), .MOSI(MOSI), .MISO(MISO)
  );

  // 100 MHz clock
  initial clk = 1'b0;
  always #5 clk = ~clk;

  // Simple slave: loop MOSI back to MISO (or drive a fixed pattern)
  always @(*) MISO = MOSI;

  initial begin
    enable   = 1'b0;
    rst      = 1'b1;
    commands = 8'h00;
    Address  = 24'd0;
    data_out = 32'd0;

    #25;
    rst = 1'b0;

    @(posedge clk);
    commands = 8'b0110_1001;
    Address  = 24'b0010_1010_1010_1010_1010_1100;
    data_out = 32'b1000_1011_1001_0101_0111_1011_0110_0101;
    enable   = 1'b1;

    repeat (4) @(posedge clk);
    enable = 1'b0;                 // single transfer

    #30000;
    $finish;
  end

endmodule
