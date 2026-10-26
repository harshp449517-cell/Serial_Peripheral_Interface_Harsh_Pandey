`timescale 1ns/1ns

module clock_divider_tb;

  initial begin
    $dumpfile("clock_tb.vcd");
    $dumpvars(0, clock_divider_tb);
  end

  reg  clk;
  reg  rst;
  wire SCLK_2;
  wire SCLK_4;

  clock_divider uut (
    .clk(clk),
    .rst(rst),
    .SCLK_2(SCLK_2),
    .SCLK_4(SCLK_4)
  );

  // 100 MHz clock
  initial clk = 1'b0;
  always #5 clk = ~clk;

  initial begin
    rst = 1'b1;
    #22;                 // hold reset across two clock edges
    rst = 1'b0;
    #10000;
    $finish;
  end

  // Simple check: SCLK_2 must toggle every clock, SCLK_4 every two clocks
  reg [1:0] expected;
  always @(posedge clk or posedge rst) begin
    if (rst) expected <= 2'b00;
    else     expected <= expected + 1'b1;
  end

  always @(negedge clk) begin
    if (!rst && {SCLK_4, SCLK_2} !== expected)
      $display("MISMATCH at %0t: got %b, expected %b", $time, {SCLK_4, SCLK_2}, expected);
  end

endmodule
