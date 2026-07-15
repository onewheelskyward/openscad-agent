// battery_holder_006.scad
// 20s5p ebike pack (26700 cells) — hex / bowling-pin option, v2:
// print-bed SECTIONING + BALANCE-LEAD lanes added over 005.
//
// Layout unchanged from 005: 10x10 hex lattice at 28mm pitch, 20 groups
// of 5 as interlocking bowling-pin trapezoids, serpentine series path,
// footprint 298.9 x 251.1 mm. Junctions alternate faces; A modeled
// mirrored (flip left-right at assembly).
//
// SECTIONING — no straight cut exists in a hex lattice (rows nest), so
// seams zigzag along the Voronoi walls between pockets: triangle-wave
// for row seams, square-wave for column seams. Min pocket-to-seam wall
// 0.55mm, same as 004's shared half-wall. Seams get seam_gap total
// clearance. NO dovetails: A-face seams (cols 2|3, 6|7; rows 2|3, 6|7)
// are staggered from B-face seams (cols 4|5; rows 4|5), so every seam is
// bridged by cells gripped in one piece on the opposite face — the cells
// interlock the pack. Strip channels crossing a seam are fine (the
// nickel strip spans the butt joint, as in 004).
//   B face: 2 x 2 pieces, ~150 x 130 max
//   A face: 3 x 3 pieces, ~127 x 106 max
// Export one piece: -D 'mode="piece"' -D 'pattern="B"' -D piece_c=0 -D piece_r=1
//
// BALANCE LEADS — 21 sense points (19 junctions + 2 terminals; terminals
// tapped at their exit lugs, no lane needed). Lanes are 2.5mm x 1.8mm
// recesses in the weld face; floor_t bumped 2.0 -> 2.6 to leave a 0.8mm
// web over lanes. A-face junctions are whole blocks touching a side edge:
// 10 straight stub lanes. B face: 6 junctions reach an edge directly;
// the 3 landlocked ones (j5, j9, j13) drop into the 3.25mm corridor
// between band pads and run to a side edge (j9 goes east — the west end
// of its corridor is blocked by the j7 bridge strip). Routes verified
// against pads, bridges, rod holes, and terminal lanes.
//
// Cell stack height now 71 + 2*2.6 = 76.2mm — M5 x 85 rods still fine.

pattern = "A";     // "A" or "B"
mode    = "sectioned";  // "full" | "sectioned" | "piece"
piece_c = 0;       // piece column index (mode="piece")
piece_r = 0;       // piece row index (mode="piece")

$fn = 48;

// ---- Cell + grid ----
cell_d    = 26.5;
clearance = 0.4;
pocket_d  = cell_d + clearance;   // 26.9
pitch     = 28;                   // center-to-center, all hex neighbors
row_p     = pitch * sin(60);      // 24.249 hex row spacing
cols      = 10;
rows      = 10;

// ---- Plate ----
pocket_depth = 10;
floor_t   = 2.6;                  // was 2.0; +0.6 for balance-lane web
plate_h   = pocket_depth + floor_t;              // 12.6
wall      = 3;
edge      = wall + pocket_d/2;                   // 16.45 to first center
plate_x   = (cols-1)*pitch + pitch/2 + 2*edge;   // 298.9
plate_y   = (rows-1)*row_p + 2*edge;             // 251.1

// ---- Welding / strips ----
weld_d      = 21;
strip_depth = 1.2;
strip_w     = 12;

// ---- Balance-lead lanes ----
lane_w = 2.5;
lane_d = 1.8;

// ---- Sectioning ----
seam_gap = 0.15;   // total clearance per seam
A_cb = [[0,2], [3,6], [7,9]];   // A-face piece column ranges (incl.)
A_rb = [[0,2], [3,6], [7,9]];   // A-face piece row ranges
B_cb = [[0,4], [5,9]];
B_rb = [[0,4], [5,9]];

// ---- Rods (side margins, in the offset-row notches) ----
bolt_d  = 5.5;
rod_x   = 9;
rod_pos = concat(
    [for (j = [1, 5, 9]) [rod_x,           edge + j*row_p]],   // odd rows inset left
    [for (j = [0, 4, 8]) [plate_x - rod_x, edge + j*row_p]]);  // even rows inset right

// Odd hex rows shift +pitch/2
function cx(i, j) = edge + i*pitch + (j % 2) * pitch/2;
function cy(j)    = edge + j*row_p;
function pt(c)    = [cx(c[0], c[1]), cy(c[1])];

// ---- Bowling-pin clusters ----
function clU(bx, by) = let (c = 5*bx, j = 2*by)
    [[c,j], [c+1,j], [c+2,j], [c,j+1], [c+1,j+1]];
function clD(bx, by) = let (c = 5*bx, j = 2*by)
    [[c+3,j], [c+4,j], [c+2,j+1], [c+3,j+1], [c+4,j+1]];

// Serpentine series order: L→R along band 0, up, R→L along band 1, ...
groups = [for (by = [0:4]) each (by % 2 == 0
    ? [clU(0,by), clD(0,by), clU(1,by), clD(1,by)]
    : [clD(1,by), clU(1,by), clD(0,by), clU(0,by)])];

function d2(a, b)   = let (p = pt(a), q = pt(b)) (p[0]-q[0])^2 + (p[1]-q[1])^2;
function argmin(v, i=0, best=0) =
    i >= len(v) ? best : argmin(v, i+1, v[i] < v[best] ? i : best);
function rev(v) = [for (i = [len(v)-1:-1:0]) v[i]];

// ---- Strip channel recesses (z=0 weld face) ----
module weld_disc(c, d) {
    p = pt(c);
    translate([p[0], p[1], -0.01]) cylinder(d=d, h=strip_depth + 0.01);
}

module group_pad(g)
    hull() for (c = groups[g]) weld_disc(c, weld_d);

// Junction k joins groups k and k+1: two group pads bridged across the
// nearest cell pair (kept narrow to clear third-party weld openings).
module junction(k) {
    pairs = [for (a = groups[k], b = groups[k+1]) [a, b]];
    bp    = pairs[argmin([for (p = pairs) d2(p[0], p[1])])];
    group_pad(k);
    group_pad(k+1);
    hull() { weld_disc(bp[0], strip_w); weld_disc(bp[1], strip_w); }
}

// Pack terminal: group pad + exit lane from cell `c` out the ±Y edge
module terminal(g, c, dir) {
    group_pad(g);
    hull() {
        weld_disc(c, strip_w);
        translate([0, dir*(edge + 10), 0]) weld_disc(c, strip_w);
    }
}

// ---- Balance-lead lanes (polylines in pack coords, weld face) ----
// Each lane starts on a cell of its junction's net and runs to an edge.
// Corridor centerline between rows j,j+1 is cy(j)+row_p/2: 0.37mm clear
// of the pad tangents (±10.5) either side.
A_lanes = [for (by = [0:4]) each [
    [pt([0, 2*by]),   [-10,          cy(2*by)]],      // block bx=0, west
    [pt([9, 2*by+1]), [plate_x + 10, cy(2*by+1)]]]];  // block bx=1, east

B_lanes = [
    [pt([4,0]), [cx(4,0), -10]],                                    // j1  south
    [pt([9,1]), [plate_x + 10, cy(1)]],                             // j3  east
    [pt([3,2]), [cx(3,2), cy(1) + row_p/2], [-10, cy(1)+row_p/2]],  // j5  corridor W
    [pt([0,2]), [-10, cy(2)]],                                      // j7  west
    [pt([3,4]), [cx(3,4), cy(3) + row_p/2],
                [plate_x + 10, cy(3) + row_p/2]],                   // j9  corridor E
    [pt([9,5]), [plate_x + 10, cy(5)]],                             // j11 east
    [pt([3,6]), [cx(3,6), cy(5) + row_p/2], [-10, cy(5)+row_p/2]],  // j13 corridor W
    [pt([0,6]), [-10, cy(6)]],                                      // j15 west
    [pt([4,8]), [cx(4,8), plate_y + 10]],                           // j17 north
];

module lane_disc(p)
    translate([p[0], p[1], -0.01]) cylinder(d=lane_w, h=lane_d + 0.01);

module lane_path(pts)
    for (i = [0:len(pts)-2])
        hull() { lane_disc(pts[i]); lane_disc(pts[i+1]); }

// ---- Plate, in pack coordinates (as seen from above) ----
module pack_face(pattern) {
    difference() {
        cube([plate_x, plate_y, plate_h]);

        for (j = [0:rows-1], i = [0:cols-1]) {
            p = [cx(i, j), cy(j)];
            // Cell pocket
            translate([p[0], p[1], floor_t])
                cylinder(d=pocket_d, h=pocket_depth + 1);
            // Entry chamfer
            translate([p[0], p[1], plate_h - 1])
                cylinder(d1=pocket_d, d2=pocket_d + 2.5, h=1.01);
            // Weld-access opening
            translate([p[0], p[1], -1])
                cylinder(d=weld_d, h=floor_t + 2);
        }

        if (pattern == "A") {
            for (k = [0:2:18]) junction(k);
        } else {
            for (k = [1:2:17]) junction(k);
            terminal(0,  groups[0][1],  -1);   // pack -, bottom-left, -Y exit
            terminal(19, groups[19][3], +1);   // pack +, top-right, +Y exit
        }

        for (L = (pattern == "A" ? A_lanes : B_lanes)) lane_path(L);

        for (p = rod_pos)
            translate([p[0], p[1], -1]) cylinder(d=bolt_d, h=plate_h + 2);
    }
}

// ---- Zigzag seams along Voronoi walls ----
// Row seam between rows j, j+1: triangle wave through the interstices,
// vertices every 14mm alternating y = cy(j) + row_p/3 and + 2*row_p/3.
function hseam_pts(j) = let (
    y0 = cy(j) + row_p/3,
    y1 = cy(j) + 2*row_p/3,
    xa = edge + ((j % 2 == 0) ? 0 : pitch/2) + pitch/2,  // a low vertex
    k0 = floor((-2 - xa) / (pitch/2)),
    k1 = ceil((plate_x + 2 - xa) / (pitch/2)))
    [for (k = [k0:k1]) [xa + k*pitch/2, (k % 2 == 0) ? y0 : y1]];

// Column seam between cols c, c+1: square wave — vertical runs at
// x = midpoint of each row's cell gap, diagonals through interstices.
function vseam_pts(c) = let (xL = edge + pitch/2 + c*pitch, xR = xL + pitch/2)
    concat(
        [[xL, -2]],
        [for (j = [0:rows-1]) each let (x = (j % 2 == 0) ? xL : xR)
            [[x, cy(j) - row_p/3], [x, cy(j) + row_p/3]]],
        [[((rows-1) % 2 == 0) ? xL : xR, plate_y + 2]]);

module ymask(rb) polygon(concat(
    rb[0] == 0      ? [[-2, -2], [plate_x + 2, -2]] : hseam_pts(rb[0] - 1),
    rb[1] == rows-1 ? [[plate_x + 2, plate_y + 2], [-2, plate_y + 2]]
                    : rev(hseam_pts(rb[1]))));

module xmask(cb) polygon(concat(
    cb[1] == cols-1 ? [[plate_x + 2, -2], [plate_x + 2, plate_y + 2]]
                    : vseam_pts(cb[1]),
    cb[0] == 0      ? [[-2, plate_y + 2], [-2, -2]] : rev(vseam_pts(cb[0] - 1))));

module piece(pattern, cb, rb) {
    intersection() {
        pack_face(pattern);
        translate([0, 0, -1]) linear_extrude(plate_h + 3)
            offset(delta=-seam_gap/2) ymask(rb);
        translate([0, 0, -1]) linear_extrude(plate_h + 3)
            offset(delta=-seam_gap/2) xmask(cb);
    }
}

module sectioned_face(pattern, sep=8) {
    cbs = pattern == "A" ? A_cb : B_cb;
    rbs = pattern == "A" ? A_rb : B_rb;
    for (ci = [0:len(cbs)-1], ri = [0:len(rbs)-1])
        translate([ci*sep, ri*sep, 0]) piece(pattern, cbs[ci], rbs[ri]);
}

// Print orientation: weld face down for both plates. A gets mirrored here
// so it lands on the pack correctly after the assembly flip.
module oriented(pattern) {
    if (pattern == "A")
        translate([plate_x, 0, 0]) mirror([1, 0, 0]) children();
    else
        children();
}

module holder_face(pattern)               oriented(pattern) pack_face(pattern);
module holder_sectioned(pattern, sep=8)   oriented(pattern) sectioned_face(pattern, sep);
module holder_piece(pattern, ci, ri)      oriented(pattern)
    piece(pattern, (pattern == "A" ? A_cb : B_cb)[ci],
                   (pattern == "A" ? A_rb : B_rb)[ri]);

if (mode == "full")           holder_face(pattern);
else if (mode == "sectioned") holder_sectioned(pattern);
else                          holder_piece(pattern, piece_c, piece_r);
