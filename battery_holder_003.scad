// battery_holder_003.scad
// 20s5p ebike pack (26700 cells) — end-plate holder SECTION, 1 of 4 per pack face.
// Full pack = 4 sections x 5 rows = 20 series groups, 5 cells per group.
// Print 8 total (4 top + 4 bottom). Weld face is the flat bottom (z=0).
//
// v3: seam margin corrected to 0 so cross-seam pitch is exactly 28mm
// (the 0.55mm half-wall already lives inside the pitch envelope; two
// abutting edges = one 1.1mm interior wall). Pack face = 20*28 = 560mm.
// v2 changes vs v1:
//  - Seam edges (+/-Y) thinned to (pitch - pocket_d)/2 so cell pitch stays
//    exactly 28mm across section seams (two abutting edges = one 1.1mm
//    interior wall). Pack face = 20*28 + 1.1 = 561.1mm long.
//  - Overlapping bolt ears removed (they collided at seams). Sections now
//    align with in-plane dovetail tenons/sockets at column boundaries;
//    clamping comes from the M5 interstitial through-rods.
//  - Floor thinned 2.5 -> 2.0 so strips dimple only 0.8mm to reach the
//    cell terminal when welding.

$fn = 64;

// ---- Cell + grid ----
cell_d       = 26.5;
clearance    = 0.4;
pocket_d     = cell_d + clearance;   // 26.9
pitch        = 28;
cols         = 5;    // cells per parallel group (X)
rows         = 5;    // series groups in this section (Y)

// ---- Plate ----
pocket_depth = 10;   // grip on cell end
floor_t      = 2.0;  // weld-face floor
plate_h      = pocket_depth + floor_t;   // 12
margin_x     = 3;                          // side walls
margin_y     = 0;                          // seams: half-wall lives in the pitch
plate_x      = cols*pitch + 2*margin_x;    // 146
plate_y      = rows*pitch + 2*margin_y;    // 140

// ---- Welding / strips ----
weld_d       = 21;    // opening exposing cell terminal
strip_depth  = 1.2;   // recess in weld face for nickel strip
strip_w      = 12;    // single-row channel width

// ---- Bolts ----
bolt_d       = 5.5;   // M5 clearance, interstitial through-rods

// ---- Seam dovetails (in plate plane, full height) ----
// Tenons on +Y edge, sockets on -Y edge, at column boundaries where the
// plate is solid. Identical sections tile by pure translation in Y.
dt_root      = 6;     // tenon width at the wall
dt_tip       = 9;     // tenon width at the tip (dovetail flare)
dt_len       = 3.2;   // protrusion
dt_slop      = 0.2;   // per-side socket clearance
dt_xs        = [margin_x + 2*pitch, margin_x + 3*pitch];  // x = 59, 87

function cx(i) = margin_x + pitch/2 + i*pitch;
function cy(j) = margin_y + pitch/2 + j*pitch;

module dovetail(root, tip, len, h) {
    linear_extrude(h)
        polygon([[-root/2, 0], [root/2, 0], [tip/2, len], [-tip/2, len]]);
}

module holder_section() {
difference() {
    union() {
        cube([plate_x, plate_y, plate_h]);
        // Tenons, +Y edge
        for (x = dt_xs)
            translate([x, plate_y - 0.01, 0])
                dovetail(dt_root, dt_tip, dt_len + 0.01, plate_h);
    }

    // Sockets, -Y edge: same shape pointing inward, oversized by dt_slop.
    // The neighbor's tenon crosses our y=0 boundary, so the void starts
    // slightly below y=0 and flares inward exactly like the tenon.
    for (x = dt_xs)
        translate([x, -0.01, -1])
            dovetail(dt_root + 2*dt_slop, dt_tip + 2*dt_slop, dt_len + 0.2,
                     plate_h + 2);

    // Cell pockets
    for (i = [0:cols-1], j = [0:rows-1])
        translate([cx(i), cy(j), floor_t])
            cylinder(d=pocket_d, h=pocket_depth + 1);

    // Entry chamfers for easy cell insertion
    for (i = [0:cols-1], j = [0:rows-1])
        translate([cx(i), cy(j), plate_h - 1])
            cylinder(d1=pocket_d, d2=pocket_d + 2.5, h=1.01);

    // Weld-access openings
    for (i = [0:cols-1], j = [0:rows-1])
        translate([cx(i), cy(j), -1])
            cylinder(d=weld_d, h=floor_t + 2);

    // Strip channels in the weld face (z=0)
    // Double channel, rows 0-1 (junction 1-2), open through -Y edge
    translate([margin_x, -1, -0.01])
        cube([plate_x - 2*margin_x,
              cy(1) + strip_w/2 + 1,
              strip_depth]);
    // Double channel, rows 2-3 (junction 3-4)
    translate([margin_x, cy(2) - strip_w/2, -0.01])
        cube([plate_x - 2*margin_x,
              (cy(3) - cy(2)) + strip_w,
              strip_depth]);
    // Single channel, row 4, open through +Y edge (junction to next section)
    translate([margin_x, cy(4) - strip_w/2, -0.01])
        cube([plate_x - 2*margin_x,
              plate_y - (cy(4) - strip_w/2) + 1,
              strip_depth]);

    // M5 through-rods at the four corner interstices
    for (a = [0, cols-2], b = [0, rows-2])
        translate([cx(a) + pitch/2, cy(b) + pitch/2, -1])
            cylinder(d=bolt_d, h=plate_h + 2);

    // Balance-lead exit slots on the -X wall, one per series junction
    for (j = [0:rows-2])
        translate([-1, cy(j) + pitch/2 - 3, -0.01])
            cube([margin_x + 2, 6, 3]);
}
}

holder_section();
