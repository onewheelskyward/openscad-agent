// battery_holder_004.scad
// 20s5p ebike pack (26700 cells) — end-plate holder SECTION.
//
// v4: restructured from 4x5-row sections to 5x4-row sections. An odd row
// count flips series-junction parity every seam, so identical 5-row plates
// can't tile; with 4 rows the parity is preserved and the whole pack needs
// exactly TWO plate types:
//   pattern = "A" (top face, print 5): junctions internal — double strip
//              channels at local rows 0-1 and 2-3.
//   pattern = "B" (bottom face, print 5): double channel at rows 1-2,
//              single channels at rows 0 and 3 opening through the +/-Y
//              edges — these carry the seam-crossing junction strips, and
//              at the two pack ends they become the main terminal exits.
// Full pack face = 5 sections x 4 rows x 28mm = 560mm x 146mm.
// Cell stack height = 71 + 2*floor_t = 75mm; use M5 x 85mm through-rods.
// NOTE: on the A face, the four through-rods land inside junction strips —
// punch 6mm holes in those strips at the rod positions.

pattern = "A";   // "A" or "B" — override with -D pattern=\"B\"

$fn = 64;

// ---- Cell + grid ----
cell_d       = 26.5;
clearance    = 0.4;
pocket_d     = cell_d + clearance;   // 26.9
pitch        = 28;
cols         = 5;    // cells per parallel group (X)
rows         = 4;    // series groups in this section (Y)

// ---- Plate ----
pocket_depth = 10;   // grip on cell end
floor_t      = 2.0;  // weld-face floor
plate_h      = pocket_depth + floor_t;   // 12
margin_x     = 3;                        // side walls
margin_y     = 0;                        // seams: half-wall lives in the pitch
plate_x      = cols*pitch + 2*margin_x;  // 146
plate_y      = rows*pitch;               // 112

// ---- Welding / strips ----
weld_d       = 21;    // opening exposing cell terminal
strip_depth  = 1.2;   // recess in weld face for nickel strip
strip_w      = 12;    // single-row channel width

// ---- Bolts ----
bolt_d       = 5.5;   // M5 clearance, interstitial through-rods

// ---- Seam dovetails (in plate plane, full height) ----
dt_root      = 6;
dt_tip       = 9;
dt_len       = 3.2;
dt_slop      = 0.2;   // per-side socket clearance
dt_xs        = [margin_x + 2*pitch, margin_x + 3*pitch];  // x = 59, 87

function cx(i) = margin_x + pitch/2 + i*pitch;
function cy(j) = margin_y + pitch/2 + j*pitch;

module dovetail(root, tip, len, h) {
    linear_extrude(h)
        polygon([[-root/2, 0], [root/2, 0], [tip/2, len], [-tip/2, len]]);
}

// Strip channel spanning rows j0..j1, optionally running out the -Y/+Y edge
module channel(j0, j1, open_neg=false, open_pos=false) {
    y0 = open_neg ? -1 : cy(j0) - strip_w/2;
    y1 = open_pos ? plate_y + 1 : cy(j1) + strip_w/2;
    translate([margin_x, y0, -0.01])
        cube([plate_x - 2*margin_x, y1 - y0, strip_depth]);
}

module holder_section(pattern) {
difference() {
    union() {
        cube([plate_x, plate_y, plate_h]);
        // Tenons, +Y edge
        for (x = dt_xs)
            translate([x, plate_y - 0.01, 0])
                dovetail(dt_root, dt_tip, dt_len + 0.01, plate_h);
    }

    // Sockets, -Y edge: same shape pointing inward, oversized by dt_slop
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
    if (pattern == "A") {
        channel(0, 1);   // junction, rows 0-1
        channel(2, 3);   // junction, rows 2-3
    } else {
        channel(0, 0, open_neg=true);   // seam junction / pack terminal
        channel(1, 2);                  // junction, rows 1-2
        channel(3, 3, open_pos=true);   // seam junction / pack terminal
    }

    // M5 through-rods at the four corner interstices
    for (a = [0, cols-2], b = [0, rows-2])
        translate([cx(a) + pitch/2, cy(b) + pitch/2, -1])
            cylinder(d=bolt_d, h=plate_h + 2);

    // Balance-lead exit slots on the -X wall, one per internal junction
    for (j = [0:rows-2])
        translate([-1, cy(j) + pitch/2 - 3, -0.01])
            cube([margin_x + 2, 6, 3]);
}
}

holder_section(pattern);
