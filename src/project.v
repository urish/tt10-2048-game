/*
 * Copyright (c) 2024 Uri Shaked
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_2048_vga_game (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // Game inputs
  wire btn_up = ui_in[0];
  wire btn_down = ui_in[1];
  wire btn_left = ui_in[2];
  wire btn_right = ui_in[3];

  // VGA signals
  wire hsync;
  wire vsync;
  reg [1:0] R;
  reg [1:0] G;
  reg [1:0] B;
  wire video_active;
  wire [9:0] pix_x;
  wire [9:0] pix_y;

  // TinyVGA PMOD
  assign uo_out  = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};

  // Unused outputs assigned to 0.
  assign uio_out = 0;
  assign uio_oe  = 0;

  // Suppress unused signals warning
  wire _unused_ok = &{ena, ui_in[7:4], uio_in};

  reg [9:0] counter;

  vga_sync_generator vga_sync_gen (
      .clk(clk),
      .reset(~rst_n),
      .hsync(hsync),
      .vsync(vsync),
      .display_on(video_active),
      .hpos(pix_x),
      .vpos(pix_y)
  );

  reg  [63:0] grid;
  wire [63:0] next_grid;

  wire [ 5:0] rrggbb;
  draw_game draw_game_inst (
      .grid(grid),
      .x(pix_x),
      .y(pix_y),
      .rrggbb(rrggbb)
  );

  game_logic game_logic_inst (
      .clk(clk),
      .rst_n(rst_n),
      .grid(next_grid),
      .btn_up(btn_up),
      .btn_right(btn_right),
      .btn_down(btn_down),
      .btn_left(btn_left)
  );

  always @(posedge clk) begin
    if (~rst_n) begin
      R <= 0;
      G <= 0;
      B <= 0;
    end else begin
      R <= video_active ? rrggbb[5:4] : 2'b00;
      G <= video_active ? rrggbb[3:2] : 2'b00;
      B <= video_active ? rrggbb[1:0] : 2'b00;
    end
  end

  always @(posedge vsync) begin
    if (~rst_n) begin
      counter <= 0;
      grid <= 0;
    end else begin
      grid <= next_grid;
      counter <= counter + 1;
    end
  end

endmodule
