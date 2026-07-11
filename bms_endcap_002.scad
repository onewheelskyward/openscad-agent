// bms_endcap_002.scad
// BMS end cap for the 20s5p pack (mates with battery_holder_004 sections).
//
// v2: sized for the actual BMS board, 126 x 66mm (thickness still assumed
// 15mm — bay depth, adjust if the board + wires need more). The board now
// fits within the frame width, so:
//  - screws moved inboard, heads flush under the board
//  - tray gains a 10mm wire-riser chase at the -X end of the bay, with a
//    floor window aligned over the (widened) frame vent window. Balance
//    leads now route fully internally: pack side -> skirt slot -> wiring
//    cavity -> frame window -> floor window -> up the riser to the board.
//    A low rib keeps the board out of the riser.
//
// Parts (both print flat, no supports), joined by 4x M3x12 flat-head + nut:
//   frame — shoes 8mm over the pack end; stop bosses leave a 6mm wiring
//           cavity. Print 2: the second caps the far pack end.
//   tray  — open bay holding the BMS board; screws to the frame outer face.
//
// part = "frame" | "tray" | "both" (side by side, as printed)

part = "both";

$fn = 64;

// ---- BMS board ----
bms_l = 126;
bms_w = 66;
bms_t = 15;

// ---- Pack interface (from battery_holder_004) ----
pack_w = 146;   // 5*28 + 2*3
pack_h = 75;    // 71 cell + 2*2 floors

// ---- Frame ----
skirt_clear = 0.2;   // per side around pack
skirt_wall  = 2.5;
plate_t     = 3;
skirt_grip  = 8;     // how far the pack inserts
wire_gap    = 6;     // cavity between pack end and plate
skirt_depth = skirt_grip + wire_gap;
frame_w     = pack_w + 2*(skirt_clear + skirt_wall);   // 151.4
frame_h     = pack_h + 2*(skirt_clear + skirt_wall);   // 80.4
vent_w      = 140;   // reaches under the tray's riser window
vent_h      = 30;

// ---- Screws (M3 flat head + nut) ----
screw_d     = 3.4;
head_d      = 6.2;
nut_af      = 5.9;   // across flats incl. slop
nut_t       = 3;
boss_d      = 9;
screw_y     = 29;

// ---- Tray ----
tray_wall   = 2.5;
tray_floor  = 2.5;
riser_w     = 10;    // wire chase at -X end of the bay
rib_t       = 2;     // rib separating riser from board
rib_h       = 6;
bay_l       = bms_l + 0.5 + rib_t + riser_w;   // 138.5
bay_w       = bms_w + 0.5;
tray_w      = bay_l + 2*tray_wall;             // 143.5
tray_h      = bay_w + 2*tray_wall;             // 71.5
tray_depth  = bms_t + 4;                       // wall height above floor

// Screws sit 6mm inside the BOARD's edges (the board is pushed +X by the
// riser chase, so its center is offset from the bay center)
board_cx    = -bay_l/2 + riser_w + rib_t + (bms_l + 0.5)/2;   // 6
screw_pos   = [for (sx = [-1, 1], sy = [-1, 1])
                  [board_cx + sx*(bms_l/2 - 6), sy*screw_y]];

module frame() {
    difference() {
        union() {
            // back plate
            translate([-frame_w/2, -frame_h/2, 0])
                cube([frame_w, frame_h, plate_t]);
            // skirt
            linear_extrude(plate_t + skirt_depth)
                difference() {
                    square([frame_w, frame_h], center=true);
                    square([pack_w + 2*skirt_clear,
                            pack_h + 2*skirt_clear], center=true);
                }
            // pack stop bosses (land on the holder plate faces)
            for (p = screw_pos)
                translate([p[0], p[1], plate_t - 0.01])
                    cylinder(d=boss_d, h=wire_gap);
        }

        // vent / wire pass-through window
        translate([-vent_w/2, -vent_h/2, -1])
            cube([vent_w, vent_h, plate_t + 2]);

        // screw holes + nut pockets (pocket opens toward the pack)
        for (p = screw_pos) {
            translate([p[0], p[1], -1])
                cylinder(d=screw_d, h=plate_t + wire_gap + 2);
            translate([p[0], p[1], plate_t + wire_gap - nut_t])
                cylinder(d=nut_af/cos(30), h=nut_t + 1, $fn=6);
        }

        // balance-lead entry slot, -X skirt (full skirt depth, 20 wide)
        translate([-frame_w/2 - 1, -10, plate_t])
            cube([skirt_wall + skirt_clear + 2, 20, skirt_depth + 1]);

        // terminal-strip slot, bottom skirt (strip exits the bottom weld
        // face channel and bends up into the wiring cavity)
        translate([-8, -frame_h/2 - 1, plate_t])
            cube([16, skirt_wall + skirt_clear + 2, skirt_depth + 1]);
    }
}

module tray() {
    difference() {
        union() {
            translate([-tray_w/2, -tray_h/2, 0])
                cube([tray_w, tray_h, tray_floor + tray_depth]);
        }

        // bay (riser chase + rib gap + board)
        translate([-bay_l/2, -bay_w/2, tray_floor])
            cube([bay_l, bay_w, tray_depth + 1]);

        // screw holes, countersunk flush with the bay floor
        for (p = screw_pos) {
            translate([p[0], p[1], -1])
                cylinder(d=screw_d, h=tray_floor + 2);
            translate([p[0], p[1], tray_floor - (head_d - screw_d)/2])
                cylinder(d1=screw_d, d2=head_d, h=(head_d - screw_d)/2 + 0.01);
        }

        // wire-riser floor window (aligns over the frame vent window)
        translate([-bay_l/2 + 1, -12, -1])
            cube([riser_w - 2, 24, tray_floor + 2]);

        // zip-tie slots
        for (sx = [-1, 1], sy = [-1, 1])
            translate([sx*bay_l/4 - 1.5, sy*(bay_w/2 - 8) - 4, -1])
                cube([3, 8, tray_floor + 2]);

        // floor vents
        for (k = [-2:2])
            translate([k*12 - 2, -bay_w/2 + 12, -1])
                cube([4, bay_w - 24, tray_floor + 2]);

        // wire notch, +X wall: charge/discharge leads out
        translate([tray_w/2 - tray_wall - 1, -6, tray_floor + 2])
            cube([tray_wall + 2, 12, tray_depth + 1]);
    }

    // rib keeping the board out of the riser chase
    translate([-bay_l/2 + riser_w, -bay_w/2, tray_floor - 0.01])
        cube([rib_t, bay_w, rib_h]);
}

if (part == "frame") frame();
else if (part == "tray") tray();
else {
    translate([0, 48, 0]) frame();
    translate([0, -45, 0]) tray();
}
