/*
 * Copyright (c) 2024 Uri Shaked
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

/** 
 * Receives data from the Gamepad Pmod and converts it to a 12/24 bit
 * value.
 * 
 * The Gamepad Pmod has a 3-pin serial interface that returns the state of
 * two SNES controllers.
 * 
 * The Pmod has 3 signals:
 * - pmod_data: The data signal from the Pmod
 * - pmod_clk: The clock signal from the Pmod
 * - pmod_latch: The latch signal from the Pmod
 * 
 * The driver can be configured to return 12 (for a single controller)
 * or 24 (for two controllers) bits of data by setting the `BIT_WIDTH`
 * parameter.
 */
module gamepad_pmod_driver #(
    parameter BIT_WIDTH = 12
) (
    input wire rst_n,
    input wire clk,
    input wire pmod_data,
    input wire pmod_clk,
    input wire pmod_latch,
    output reg [BIT_WIDTH-1:0] data_reg
);

  reg pmod_clk_prev;
  reg pmod_latch_prev;

  // Shift register for the pmod data:
  reg [BIT_WIDTH-1:0] shift_reg;

  // Sync pmod signals to the clk domain:
  reg [1:0] pmod_data_sync;
  reg [1:0] pmod_clk_sync;
  reg [1:0] pmod_latch_sync;

  always @(posedge clk) begin
    if (~rst_n) begin
      pmod_data_sync  <= 2'b0;
      pmod_clk_sync   <= 2'b0;
      pmod_latch_sync <= 2'b0;
    end else begin
      pmod_data_sync  <= {pmod_data_sync[0], pmod_data};
      pmod_clk_sync   <= {pmod_clk_sync[0], pmod_clk};
      pmod_latch_sync <= {pmod_latch_sync[0], pmod_latch};
    end
  end

  always @(posedge clk) begin
    if (~rst_n) begin
      shift_reg <= 0;
      data_reg <= 0;
      pmod_clk_prev <= 1'b0;
      pmod_latch_prev <= 1'b0;
    end
    begin
      pmod_clk_prev   <= pmod_clk_sync[1];
      pmod_latch_prev <= pmod_latch_sync[1];

      if (pmod_latch_sync[1] & ~pmod_latch_prev) begin
        // Latch just went up, latch the data from the shift register
        data_reg <= shift_reg;
      end
      if (~pmod_clk_sync[1] & pmod_clk_prev) begin
        // Clock just went down, shift in new data bit from pmod_data_sync[1]
        shift_reg <= {shift_reg[BIT_WIDTH-2:0], pmod_data_sync[1]};
      end
    end
  end

endmodule
