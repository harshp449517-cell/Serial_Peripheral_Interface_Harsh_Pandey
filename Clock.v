module clock_divider (
    input  clk,
    input  rst,
    output SCLK_2,      // clk / 2
    output SCLK_4       // clk / 4
);

reg [1:0] clk_count;

always @(posedge clk or posedge rst) begin
    if (rst)
        clk_count <= 2'b00;
    else
        clk_count <= clk_count + 1'b1;
end

assign SCLK_2 = clk_count[0];
assign SCLK_4 = clk_count[1];

endmodule
