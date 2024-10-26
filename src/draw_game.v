/*
 * Copyright (c) 2024 Uri Shaked
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module draw_game (
    input wire [63:0] grid,
    input wire [15:0] new_tiles,
    input wire [2:0] new_tiles_counter,
    input wire [9:0] x,
    input wire [9:0] y,
    input wire retro_colors,
    input wire debug_mode,
    output reg [5:0] rrggbb
);

  localparam CELL_SIZE = 64;
  localparam BOARD_X_POS = 192;
  localparam BOARD_Y_POS = 128;
  localparam BOARD_WIDTH = CELL_SIZE * 4;
  localparam BOARD_HEIGHT = CELL_SIZE * 4;
  localparam BOARD_X_RIGHT = BOARD_X_POS + BOARD_WIDTH;
  localparam BOARD_Y_BOTTOM = BOARD_Y_POS + BOARD_HEIGHT;

  wire [5:0] color_font = retro_colors ? 6'b101110 : 6'b001111;
  wire [5:0] color_bg = retro_colors ? {3'b000, x[0], 2'b00} : 0;
  wire [5:0] color_outline = retro_colors ? 6'b001000 : 6'b111111;

  wire [9:0] board_x = x - BOARD_X_POS;
  wire [9:0] board_y = y - BOARD_Y_POS;
  wire [1:0] cell_x = board_x[7:6];
  wire [1:0] cell_y = board_y[7:6];
  wire [5:0] cell_offset = {cell_y, cell_x, 2'b00};
  wire [3:0] current_number = grid[cell_offset+:4];
  wire is_new_tile = new_tiles_counter > 0 && new_tiles[{cell_y, cell_x}];

  // Determine if we're on the outline
  wire is_outline_x = (x % CELL_SIZE == 0 || x % CELL_SIZE == (CELL_SIZE - 1));
  wire is_outline_y = (y % CELL_SIZE == 0 || y % CELL_SIZE == (CELL_SIZE - 1));
  wire is_outline = is_outline_x || is_outline_y;

  wire pixel;

  draw_numbers draw_numbers_inst (
      .index(current_number),
      .x(x[5:0]),
      .y(y[5:0]),
      .pixel(pixel)
  );

  wire board_area = x >= BOARD_X_POS && y >= BOARD_Y_POS && x < BOARD_X_RIGHT && y < BOARD_Y_BOTTOM;
  wire [5:0] fade_font_color = 6'b001111 ^ {3'b0, new_tiles_counter};
  wire [5:0] draw_text = is_new_tile ? fade_font_color : color_font;
  wire [5:0] draw_board = is_outline ? color_outline : color_bg;

  wire debug_rect = x >= BOARD_X_POS - 64 && x < BOARD_X_RIGHT + 64 && y >= 16 && y < 32;

  always @(*) begin
    rrggbb = board_area ? pixel ? draw_text : draw_board : debug_mode && debug_rect ? x[8:3] : 6'b0;
  end

endmodule
