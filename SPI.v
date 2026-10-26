module SPI_Master (
  input  wire        clk,
  input  wire        rst,
  input  wire        enable,
  input  wire [31:0] data_out,
  input  wire [7:0]  commands,
  input  wire [23:0] Address,
  input  wire        MISO,          // input to the master
  output reg         CS,
  output reg         SCLK,
  output reg         MOSI
);

  localparam IDLE = 2'b00, START = 2'b01, TRANSFER = 2'b10, STOP = 2'b11;
  localparam WRITE_CMD = 8'b0110_1001;
  localparam READ_CMD = 8'b0110_1010;
  reg [1:0]  state, next_state;
  reg [31:0] shift_reg;
  reg [5:0]  bit_cnt;
  reg [31:0] slave_reg;
  reg        sclk_en;
  reg        sclk_phase;

  // SCLK generation: single driver, divide clk by 2 while active
  always @(posedge clk) begin
    if (rst) begin
      SCLK       <= 1'b1;
      sclk_phase <= 1'b0;
    end else if (sclk_en) begin
      sclk_phase <= ~sclk_phase;
      SCLK       <= sclk_phase;
    end else begin
      SCLK       <= 1'b1;
      sclk_phase <= 1'b0;
    end
  end

  // State register, shift register, and counters (all clocked)
  always @(posedge clk) begin
    if (rst) begin
      state     <= IDLE;
      bit_cnt   <= 6'd0;
      shift_reg <= 32'd0;
      slave_reg <= 32'd0;
      MOSI      <= 1'b0;
    end else begin
      state <= next_state;
      case (state)
        IDLE: begin
          bit_cnt   <= 6'd0;
          shift_reg <= {Address, commands};
        end
        START, TRANSFER: begin
          if (sclk_phase) begin             // update on one clock phase
            MOSI      <= shift_reg[31];
            shift_reg <= {shift_reg[30:0], 1'b0};
            slave_reg <= {slave_reg[30:0], MISO};
            bit_cnt   <= bit_cnt + 1'b1;
          end
          if (state == START && bit_cnt == 6'd32) begin
            bit_cnt   <= 6'd0;
            shift_reg <= data_out;
          end
        end
        default: ;
      endcase
    end
  end

  // Next-state and output logic (purely combinational, with defaults)
  always @(*) begin
    next_state = state;
    CS         = 1'b1;
    sclk_en    = 1'b0;
    case (state)
      IDLE: begin
        if (enable) next_state = START;
      end
      START: begin
        CS      = 1'b0;
        sclk_en = 1'b1;
        if (bit_cnt == 6'd32) next_state = TRANSFER;
      end
      TRANSFER: begin
        CS      = 1'b0;
        sclk_en = 1'b1;
        if (commands == WRITE_CMD) begin
          if (bit_cnt == 6'd32) next_state = STOP;
        end else begin
          next_state = STOP;   // read command: add receive logic here
        end
      end
      STOP: next_state = IDLE;
      default: next_state = IDLE;
    endcase
  end

endmodule
