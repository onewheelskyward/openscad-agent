// battery_holder_005.scad
// 20s5p ebike pack (26700 cells) — OPTION 2: hex close packing with
// parallel groups of 5 arranged as bowling-pin clusters.
//
// Lattice: 10 cols x 10 hex rows, same 28mm pitch to all six neighbors,
// row spacing 28*sin(60) = 24.25. Each 5-cell group is a "bowling pin"
// trapezoid (3 cells + 2 nested). An up-cluster and a down-cluster
// interlock into a 5-wide x 2-row block with zero empty lattice sites;
// 2 x 5 blocks tile the face. Series path snakes through the 20 clusters.
//
// Footprint: 298.9 x 251.1 mm vs option 1's 560 x 146 — ~8% less area
// and near-square instead of 4:1. Cell stack height unchanged:
// 71 + 2*floor_t = 75mm, M5 x 85mm through-rods.
//
// pattern "A" (top plate): strip channels for the 10 even junctions.
//   The hex lattice is NOT mirror-symmetric, so A is modeled mirrored:
//   print weld-face down as modeled, then flip left-right onto the pack.
// pattern "B" (bottom plate): the 9 odd junctions plus both pack-terminal
//   channels, which run out the -Y and +Y edges at opposite corners.
// Cell orientation alternates per group (even groups +up, odd +down) so
// every junction connects opposite polarities.
//
// Channels are per-group hulls joined by a 12mm bridge across the nearest
// cell pair — full two-group hulls would overlap neighboring groups' weld
// openings (shorting risk), verified clearances: 7mm hull-to-foreign-hull,
// 3.25mm between hex rows.
//
// Open items vs option 1: single full-face plate (no print-bed sectioning
// yet), no balance-lead slots yet, and through-rods moved to the side
// margins — hex interstices are only r=2.7mm, too tight for M5.

pattern = "A";   // "A" or "B"

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
floor_t   = 2.0;
plate_h   = pocket_depth + floor_t;              // 12
wall      = 3;
edge      = wall + pocket_d/2;                   // 16.45 to first center
plate_x   = (cols-1)*pitch + pitch/2 + 2*edge;   // 298.9
plate_y   = (rows-1)*row_p + 2*edge;             // 251.1

// ---- Welding / strips ----
weld_d      = 21;
strip_depth = 1.2;
strip_w     = 12;

// ---- Rods (side margins, in the offset-row notches) ----
bolt_d  = 5.5;
rod_x   = 9;   // hole center inset from plate edge
rod_pos = concat(
    [for (j = [1, 5, 9]) [rod_x,           edge + j*row_p]],   // odd rows inset left
    [for (j = [0, 4, 8]) [plate_x - rod_x, edge + j*row_p]]);  // even rows inset right

// Odd hex rows shift +pitch/2
function cx(i, j) = edge + i*pitch + (j % 2) * pitch/2;
function cy(j)    = edge + j*row_p;

// ---- Bowling-pin clusters ----
// Block (bx,by) covers cols 5bx..5bx+4, rows 2by..2by+1.
// Up cluster: 3 cells on the lower row, 2 nested above.
// Down cluster: 2 on the lower row, 3 above — interlocks with Up.
function clU(bx, by) = let (c = 5*bx, j = 2*by)
    [[c,j], [c+1,j], [c+2,j], [c,j+1], [c+1,j+1]];
function clD(bx, by) = let (c = 5*bx, j = 2*by)
    [[c+3,j], [c+4,j], [c+2,j+1], [c+3,j+1], [c+4,j+1]];

// Serpentine series order: L→R along band 0, up, R→L along band 1, ...
groups = [for (by = [0:4]) each (by % 2 == 0
    ? [clU(0,by), clD(0,by), clU(1,by), clD(1,by)]
    : [clD(1,by), clU(1,by), clD(0,by), clU(0,by)])];

function pt(c)      = [cx(c[0], c[1]), cy(c[1])];
function d2(a, b)   = let (p = pt(a), q = pt(b)) (p[0]-q[0])^2 + (p[1]-q[1])^2;
function argmin(v, i=0, best=0) =
    i >= len(v) ? best : argmin(v, i+1, v[i] < v[best] ? i : best);

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

        for (p = rod_pos)
            translate([p[0], p[1], -1]) cylinder(d=bolt_d, h=plate_h + 2);
    }
}

// Print orientation: weld face down for both plates. A gets mirrored here
// so it lands on the pack correctly after the assembly flip.
module holder_face(pattern) {
    if (pattern == "A")
        translate([plate_x, 0, 0]) mirror([1, 0, 0]) pack_face("A");
    else
        pack_face("B");
}

holder_face(pattern);
