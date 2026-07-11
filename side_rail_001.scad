// side_rail_001.scad
// Side rail / balance-lead raceway for the 20s5p pack.
//
// C-channel that snaps over the pack's -X side, covering the balance-wire
// run and stiffening the pack lengthwise. The walls grip the top/bottom
// pack faces with 0.4mm interference; the final pack wrap locks it down.
// No changes to already-printed parts required.
//
// The end-cap skirts cover 8mm at each pack end, so the free span is
// 560 - 2*8 = 544mm. Print 3 rails (~181.3mm each): laid end to end they
// bridge the holder section seams like brickwork, tying sections together.
// Optionally print 3 more for the +X side (no wires, pure stiffening).
//
// Walls ride on the pack faces 13mm in from the edge — clear of the rod
// nuts (28mm in) — and the strip channels are recessed, so the faces are
// flat where the walls land. The 7mm cavity swallows the full 21-wire
// balance bundle with room to spare.

$fn = 64;

rail_l   = 544/3;   // ~181.3 — three per side
pack_h   = 75;      // cell 71 + 2*2 floors
grip     = 0.4;     // total interference across the faces
web_t    = 2.5;
wall_t   = 2.5;
cavity   = 7;       // wire room between web and pack side
wall_len = cavity + 6;   // walls lap 6mm onto the pack faces
outer_h  = pack_h - grip + 2*wall_t;   // 79.6

// Printed web-down; the C opens upward.
difference() {
    union() {
        // web
        cube([rail_l, outer_h, web_t]);
        // walls
        cube([rail_l, wall_t, web_t + wall_len]);
        translate([0, outer_h - wall_t, 0])
            cube([rail_l, wall_t, web_t + wall_len]);
    }

    // lead-in chamfers on the wall tips (inside faces)
    translate([-1, wall_t + 1.5, web_t + wall_len + 0.01])
        rotate([135, 0, 0])
        cube([rail_l + 2, 4, 4]);
    translate([-1, outer_h - wall_t - 1.5, web_t + wall_len + 0.01])
        rotate([135, 0, 0])
        translate([0, -4, -4])
        cube([rail_l + 2, 4, 4]);
}
