/*
 * Copyright (c) 2024 Uri Shaked
 * SPDX-License-Identifier: Apache-2.0
 */

module game_logic (
    input wire clk,
    input wire rst_n,
    input wire btn_up,
    input wire btn_right,
    input wire btn_down,
    input wire btn_left,
    output reg [63:0] grid
);

  function [15:0] push_and_merge_row(input [15:0] row, input direction);
    reg [3:0] result_0, result_1, result_2, result_3;
    reg [3:0] value;
    integer i, j;
    begin
      // Initialize result cells to 0
      result_0 = 4'b0000;
      result_1 = 4'b0000;
      result_2 = 4'b0000;
      result_3 = 4'b0000;

      j = 0;  // Index to track the current position in the result

      // Process each cell in the row
      for (i = 0; i < 4; i = i + 1) begin
        value = row[15-i*4-:4];  // Extract each 4-bit cell starting from the left

        if (value != 4'b0000) begin
          case (j)
            0: result_0 = value;
            1: begin
              if (value == result_0) begin
                result_0 = result_0 + 1;  // Merge with the previous value
                j = j - 1;  // Reduce j as the merge took place
              end else begin
                result_1 = value;
              end
            end
            2: begin
              if (value == result_1) begin
                result_1 = result_1 + 1;  // Merge with the previous value
                j = j - 1;  // Reduce j as the merge took place
              end else begin
                result_2 = value;
              end
            end
            3: begin
              if (value == result_2) begin
                result_2 = result_2 + 1;  // Merge with the previous value
                j = j - 1;  // Reduce j as the merge took place
              end else begin
                result_3 = value;
              end
            end
          endcase
          j = j + 1;
        end
      end

      // Combine result cells into a single 16-bit value
      push_and_merge_row = direction ? {result_0, result_1, result_2, result_3} : {result_3, result_2, result_1, result_0};
    end
  endfunction

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
  wire [63:0] transposed_grid = transpose_grid(grid);

  always @(posedge clk) begin
    if (~rst_n) begin
      counter <= 3;
      add_new_tiles <= 2;
      grid <= 0;
    end else begin
      counter <= counter + 1;
      if (counter == 32) begin
        counter <= 0;
      end
      if (btn_left || btn_right) begin
        grid <= {
          push_and_merge_row(grid[63:48], btn_right),
          push_and_merge_row(grid[47:32], btn_right),
          push_and_merge_row(grid[31:16], btn_right),
          push_and_merge_row(grid[15:0], btn_right)
        };
        add_new_tiles <= 1;
      end else if (btn_up || btn_down) begin
        grid <= transpose_grid(
            {
              push_and_merge_row(transposed_grid[63:48], btn_down),
              push_and_merge_row(transposed_grid[47:32], btn_down),
              push_and_merge_row(transposed_grid[31:16], btn_down),
              push_and_merge_row(transposed_grid[15:0], btn_down)
            }
        );
        add_new_tiles <= 1;
      end else if (add_new_tiles != 0) begin
        if (grid[{counter[3:0]}*4+:4] == 0) begin
          grid[{counter[3:0]}*4+:4] <= 1;
          add_new_tiles <= add_new_tiles - 1;
        end
      end
    end
  end
endmodule
