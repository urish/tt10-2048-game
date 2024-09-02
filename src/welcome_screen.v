/*
 * Copyright (c) 2024 Uri Shaked
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module welcome_screen (
    input wire clk,
    input wire rst_n,
    input wire vsync_rising_edge,
    input wire [3:0] lfsr_out,
    output reg [63:0] grid
);

  reg [4:0] welcome_counter;

  always @(posedge clk) begin
    if (~rst_n) begin
      welcome_counter <= 5'b0;
    end else begin
      if (welcome_counter == 5'd30) begin  // 30 frames == 0.5 seconds
        if (grid[lfsr_out*4+:4] == 4'd0) begin
          grid <= 0;
          grid[lfsr_out*4+:4] <= 4'd11;  // displays 2048 (2^11)
          welcome_counter <= 0;
        end
      end else if (vsync_rising_edge) begin
        welcome_counter <= welcome_counter + 1;
      end
    end
  end
endmodule
