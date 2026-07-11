// battery_holder_001.scad
// 20s5p ebike pack (26700 cells) — end-plate holder SECTION, 1 of 4 per pack face.
// Full pack = 4 sections x 5 rows = 20 series groups, 5 cells per group.
// Print 8 total (4 top + 4 bottom). Weld face is the flat bottom (z=0).
//
// Cell: 26.5mm dia x 71mm long. Square grid, 28mm pitch.
// Series junction strips are full-width double-row channels; the pattern
// alternates faces, so this plate carries junctions 1-2 and 3-4, and the
// opposing plate carries 2-3 and 4-5. Channels run out the +/-Y edges so
// strips can cross the seam to neighboring sections.

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
floor_t      = 2.5;  // weld-face floor
plate_h      = pocket_depth + floor_t;   // 12.5
margin       = 3;    // wall beyond grid envelope
plate_x      = cols*pitch + 2*margin;    // 146
plate_y      = rows*pitch + 2*margin;    // 146

// ---- Welding / strips ----
weld_d       = 21;    // opening exposing cell terminal
strip_depth  = 1.2;   // recess in weld face for nickel strip
strip_w      = 12;    // single-row channel width

// ---- Bolts ----
bolt_d       = 5.5;   // M5 clearance, interstitial through-rods

// ---- Joining ears (sections bolt together at seams) ----
// +Y ears sit in the lower half, -Y ears in the upper half, at the same
// columns — so at a seam the neighbor's ear stacks on top and one vertical
// M5 ties both sections together.
ear_w        = 16;
ear_d        = 9;     // protrusion
ear_t        = 6;     // thickness
ear_cols     = [1, 3];

function cx(i) = margin + pitch/2 + i*pitch;
function cy(j) = margin + pitch/2 + j*pitch;

module ear_hole(x, y) {
    translate([x, y, -1]) cylinder(d=bolt_d, h=plate_h + 2);
}

difference() {
    union() {
        cube([plate_x, plate_y, plate_h]);

        // +Y ears, lower half
        for (i = ear_cols)
            translate([cx(i) - ear_w/2, plate_y, 0])
                cube([ear_w, ear_d, ear_t]);

        // -Y ears, upper half, chamfered down to the wall for printability
        for (i = ear_cols)
            hull() {
                translate([cx(i) - ear_w/2, -ear_d, plate_h - ear_t])
                    cube([ear_w, ear_d, ear_t]);
                translate([cx(i) - ear_w/2, -0.1, 0])
                    cube([ear_w, 0.1, plate_h]);
            }
    }

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
    translate([margin, -1, -0.01])
        cube([plate_x - 2*margin,
              cy(1) + strip_w/2 + 1,
              strip_depth]);
    // Double channel, rows 2-3 (junction 3-4)
    translate([margin, cy(2) - strip_w/2, -0.01])
        cube([plate_x - 2*margin,
              (cy(3) - cy(2)) + strip_w,
              strip_depth]);
    // Single channel, row 4, open through +Y edge (junction to next section)
    translate([margin, cy(4) - strip_w/2, -0.01])
        cube([plate_x - 2*margin,
              plate_y - (cy(4) - strip_w/2) + 1,
              strip_depth]);

    // M5 through-rods at the four corner interstices
    for (a = [0, cols-2], b = [0, rows-2])
        translate([cx(a) + pitch/2, cy(b) + pitch/2, -1])
            cylinder(d=bolt_d, h=plate_h + 2);

    // Ear bolt holes
    for (i = ear_cols) {
        ear_hole(cx(i), plate_y + ear_d/2);
        ear_hole(cx(i), -ear_d/2);
    }

    // Balance-lead exit slots on the -X wall, one per series junction
    for (j = [0:rows-2])
        translate([-1, cy(j) + pitch/2 - 3, -0.01])
            cube([margin + 2, 6, 3]);
}
