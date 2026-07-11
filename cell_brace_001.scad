// cell_brace_001.scad
// Mid-span cell brace for the 20s5p pack (mates with battery_holder_004).
// The end plates grip only 10mm of each cell end, leaving 51mm of cell
// unsupported — this brace ties the cells together at mid-height.
//
// Two parts:
//   brace  — 5x4 plate matching a holder section (print 5). Through-holes
//            at 27.2mm slide over the cells during assembly (cells first,
//            then brace, then top plates). Same dovetails as the holder
//            sections so braces tile at the same seams; same M5 rod
//            positions so the through-rods pass through.
//   sleeve — rod spacer tube, 21.5mm (print 40: one above and one below
//            the brace on each of the 20 rods). Sleeves locate the brace
//            at mid-span AND act as compression limiters: the clamp path
//            becomes plate->sleeve->brace->sleeve->plate, totalling
//            exactly 12 + 21.5 + 8 + 21.5 + 12 = 75mm = the cell stack,
//            so rod torque can't crush the cells.
//
// part = "brace" | "sleeve" | "both"

part = "both";

$fn = 64;

// ---- Shared with battery_holder_004 ----
pitch    = 28;
cols     = 5;
rows     = 4;
margin_x = 3;
plate_x  = cols*pitch + 2*margin_x;   // 146
plate_y  = rows*pitch;                // 112
bolt_d   = 5.8;    // slightly loose — the sleeves do the aligning

dt_root  = 6;
dt_tip   = 9;
dt_len   = 3.2;
dt_slop  = 0.2;
dt_xs    = [margin_x + 2*pitch, margin_x + 3*pitch];

// ---- Brace ----
brace_h  = 8;
hole_d   = 27.2;   // extra clearance: slides 35mm down over 20 cells
chamfer  = 1.2;    // lead-in, both faces

// ---- Sleeve ----
sleeve_od = 10;
sleeve_id = 5.8;
sleeve_l  = 21.5;  // (75 - 8 - 2*12) / 2

function cx(i) = margin_x + pitch/2 + i*pitch;
function cy(j) = pitch/2 + j*pitch;

module dovetail(root, tip, len, h) {
    linear_extrude(h)
        polygon([[-root/2, 0], [root/2, 0], [tip/2, len], [-tip/2, len]]);
}

module brace() {
    difference() {
        union() {
            cube([plate_x, plate_y, brace_h]);
            for (x = dt_xs)
                translate([x, plate_y - 0.01, 0])
                    dovetail(dt_root, dt_tip, dt_len + 0.01, brace_h);
        }

        for (x = dt_xs)
            translate([x, -0.01, -1])
                dovetail(dt_root + 2*dt_slop, dt_tip + 2*dt_slop,
                         dt_len + 0.2, brace_h + 2);

        // cell through-holes with lead-in chamfers on both faces
        for (i = [0:cols-1], j = [0:rows-1]) {
            translate([cx(i), cy(j), -1])
                cylinder(d=hole_d, h=brace_h + 2);
            translate([cx(i), cy(j), -0.01])
                cylinder(d1=hole_d + 2*chamfer, d2=hole_d, h=chamfer);
            translate([cx(i), cy(j), brace_h - chamfer + 0.01])
                cylinder(d1=hole_d, d2=hole_d + 2*chamfer, h=chamfer);
        }

        // M5 through-rod holes at the corner interstices
        for (a = [0, cols-2], b = [0, rows-2])
            translate([cx(a) + pitch/2, cy(b) + pitch/2, -1])
                cylinder(d=bolt_d, h=brace_h + 2);
    }
}

module sleeve() {
    difference() {
        cylinder(d=sleeve_od, h=sleeve_l);
        translate([0, 0, -1]) cylinder(d=sleeve_id, h=sleeve_l + 2);
    }
}

if (part == "brace") brace();
else if (part == "sleeve") sleeve();
else {
    brace();
    for (k = [0:7])
        translate([12 + k*16, -18, 0]) sleeve();
}
