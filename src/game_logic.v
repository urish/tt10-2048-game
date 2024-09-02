/*
 * Copyright (c) 2024 Uri Shaked
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module game_logic (
    input wire clk,
    input wire rst_n,
    input wire btn_up,
    input wire btn_right,
    input wire btn_down,
    input wire btn_left,
    output reg [63:0] grid
);

  function [63:0] transpose_grid(input [63:0] grid_in);
    reg [63:0] transposed_grid;
    begin
      transposed_grid[63:60] = grid_in[63:60];  // Row 0, Col 0 -> Row 0, Col 0
      transposed_grid[59:56] = grid_in[47:44];  // Row 1, Col 0 -> Row 0, Col 1
      transposed_grid[55:52] = grid_in[31:28];  // Row 2, Col 0 -> Row 0, Col 2
      transposed_grid[51:48] = grid_in[15:12];  // Row 3, Col 0 -> Row 0, Col 3

      transposed_grid[47:44] = grid_in[59:56];  // Row 0, Col 1 -> Row 1, Col 0
      transposed_grid[43:40] = grid_in[43:40];  // Row 1, Col 1 -> Row 1, Col 1
      transposed_grid[39:36] = grid_in[27:24];  // Row 2, Col 1 -> Row 1, Col 2
      transposed_grid[35:32] = grid_in[11:8];  // Row 3, Col 1 -> Row 1, Col 3

      transposed_grid[31:28] = grid_in[55:52];  // Row 0, Col 2 -> Row 2, Col 0
      transposed_grid[27:24] = grid_in[39:36];  // Row 1, Col 2 -> Row 2, Col 1
      transposed_grid[23:20] = grid_in[23:20];  // Row 2, Col 2 -> Row 2, Col 2
      transposed_grid[19:16] = grid_in[7:4];  // Row 3, Col 2 -> Row 2, Col 3

      transposed_grid[15:12] = grid_in[51:48];  // Row 0, Col 3 -> Row 3, Col 0
      transposed_grid[11:8] = grid_in[35:32];  // Row 1, Col 3 -> Row 3, Col 1
      transposed_grid[7:4] = grid_in[19:16];  // Row 2, Col 3 -> Row 3, Col 2
      transposed_grid[3:0] = grid_in[3:0];  // Row 3, Col 3 -> Row 3, Col 3

      transpose_grid = transposed_grid;
    end
  endfunction

  reg [9:0] counter;
  reg [1:0] add_new_tiles;
  reg [1:0] current_direction;

  reg button_pressed;
  reg should_transpose;
  wire [63:0] transposed_grid = transpose_grid(grid);
  reg [1:0] current_row_index;
  wire [15:0] current_row = grid[current_row_index*16+:16];
  wire [15:0] current_row_pushed_merged;

  game_row_push_merge push_merge (
      .row(current_row),
      .direction(current_direction[0]),
      .result_row(current_row_pushed_merged)
  );

  always @(posedge clk) begin
    if (~rst_n) begin
      counter <= 3;
      add_new_tiles <= 2;
      grid <= 0;
      button_pressed <= 0;
      current_direction <= 0;
      current_row_index <= 0;
      should_transpose <= 0;
    end else begin
      counter <= counter + 1;
      if (counter == 32) begin
        counter <= 0;
      end
      if (btn_left | btn_right | btn_up | btn_down) begin
        if (btn_left) begin
          current_direction <= 2'd0;
        end else if (btn_right) begin
          current_direction <= 2'd1;
        end else if (btn_up) begin
          current_direction <= 2'd2;
        end else if (btn_down) begin
          current_direction <= 2'd3;
        end
        if (btn_up | btn_down) begin
          should_transpose <= 1;
        end
        current_row_index <= 0;
        button_pressed <= 1;
      end else if (should_transpose) begin
        grid <= transposed_grid;
        should_transpose <= 0;
      end else if (button_pressed) begin
        grid[current_row_index*16+:16] <= current_row_pushed_merged;
        current_row_index <= current_row_index + 1;
        if (current_row_index == 2'd3) begin
          if (current_direction >= 2) begin
            should_transpose <= 1;
          end
          add_new_tiles  <= 1;
          button_pressed <= 0;
        end
      end else if (add_new_tiles != 0) begin
        if (grid[{counter[3:0]}*4+:4] == 0) begin
          grid[{counter[3:0]}*4+:4] <= 1;
          add_new_tiles <= add_new_tiles - 1;
        end
      end
    end
  end
endmodule
