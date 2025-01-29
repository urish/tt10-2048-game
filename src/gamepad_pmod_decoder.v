/*
 * Copyright (c) 2024 Uri Shaked
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

/*
 * gamepad_pmod_decoder: Decodes the data from an individual SNES-compatible 
 * gamepad connected to the gamepad Pmod.
*/

module gamepad_pmod_decoder (
    input wire [11:0] data_reg,
    output wire b,
    output wire y,
    output wire select,
    output wire start,
    output wire up,
    output wire down,
    output wire left,
    output wire right,
    output wire a,
    output wire x,
    output wire l,
    output wire r,
    output wire is_present
);

  // When the controller is not connected, the data register will be all 1's
  wire reg_empty = (data_reg == 12'hfff);
  assign is_present = reg_empty ? 0 : 1'b1;
  assign {b, y, select, start, up, down, left, right, a, x, l, r} = reg_empty ? 0 : data_reg;

endmodule
