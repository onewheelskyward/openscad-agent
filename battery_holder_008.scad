// battery_holder_008.scad
// 20s5p ebike pack (26700 cells) — hex / bowling-pin option, v4:
// STEPPED SACRIFICIAL BRIDGES under the weld openings (print quality fix).
// Otherwise identical to 007 (2x2 sectioning, seam dovetails, tie bolts).
//
// STEPPED BRIDGES (v4) — printed weld-face-up, the pocket ceiling is a
// ~2.95mm annular ledge (pocket_d 26.9 -> weld_d 21) that printed as
// unsupported rings and got stringy (007 field report). Fix: the round
// weld window stops 2*br_step short of the ceiling; the last two stages
// open as a SLOT (printed first, circle-segment bridges anchored on the
// pocket wall) then a SQUARE (strips bridging onto the slot slivers), and
// the d21 circle prints on the square's corner material. Both stage voids
// fully contain the d21 circle, so the electrode path is unobstructed;
// the stages live in the sacrificial part of the ceiling annulus only.
// br_step should equal the slicer layer height (default 0.2). Print with
// NO supports.
//
// Layout unchanged from 006: 10x10 hex lattice at 28mm pitch, 20 groups
// of 5 as interlocking bowling-pin trapezoids, serpentine series path,
// footprint 298.9 x 251.1 mm. Junctions alternate faces; A modeled
// mirrored (flip left-right at assembly).
//
// SECTIONING (v3) — A face was 3x3 (9 pieces, hard to assemble); now BOTH
// faces are 2x2 = 8 pieces total. A seams moved to cols 2|3 / rows 2|3,
// staggered two cells from B's (cols 4|5 / rows 4|5) so every seam is
// still bridged by cells gripped in one piece on the opposite face.
//   A pieces: ~100x81 min, ~212x178 max — fits MK4S 250x210 bed
//   B pieces: ~150x130 max (unchanged)
// Export one piece: -D 'mode="piece"' -D 'pattern="A"' -D piece_c=0 -D piece_r=1
//
// DOVETAILS (v3) — full-height keys along every seam for in-plane rigidity.
// The only room on a hex seam is the tri-cell interstice: a 5.43mm-dia free
// circle at each zigzag vertex (pitch/sqrt(3) - pocket_d/2 = 2.72mm radius).
// Keys are small flared trapezoids inscribed in those circles:
//   row seams: at triangle-wave HIGH vertices, 1.8 -> 2.8mm over 3.6mm,
//              owned by the lower piece, pointing +Y
//   col seams: at square-wave top-of-run corners, 1.6 -> 2.6mm over 3.2mm,
//              owned by the left piece, pointing +X
// Min key-to-pocket wall 0.58mm (>= the 0.55 seam-wall precedent). Keys get
// key_gap total clearance (0.25 vs 0.15 butt seams — 6 keys engage at once,
// tolerance stacks). Positions skip the seam crossing and the tie bolts.
//
// INTERIOR TIE BOLTS (v3) — 5 x M4 through-holes (4.3mm) so the pack can't
// blow out in the middle; heads/nuts bear on the outer weld faces. Bolts
// also pass through interstice columns; a valid interstice needs all THREE
// surrounding cells in three DIFFERENT groups (else a group pad hull covers
// it), which only happens in between-band corridors (rows 1|2, 3|4, 5|6,
// 7|8) at cluster x-boundaries. Positions below also clear balance lanes
// (j5 owns corridor 1|2 west, j9 owns 3|4 east, j13 owns 5|6 west), both
// faces' seams + keys, junction bridges, and terminal exits — verified for
// washers up to 9mm OD (weld-opening rims are 5.67mm from any interstice).
// Wall from bolt hole to pocket: (5.43-4.3)/2 = 0.57mm; bolt shank clears
// bare cell wrap by ~0.9mm. USE NYLON M4 RODS or heat-shrink steel ones —
// they run the full interstitial channel between live cells.
//
// Cell stack 71 + 2*2.6 = 76.2mm across outer faces — M4 x 85 works.
//
// PRINT ORIENTATION (unchanged from 006 v2): pieces export weld-face-UP
// (pocket mouths on the bed) — weld-face-down left the thin floor bridging
// over every recess. Print with a brim; no supports needed.

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
floor_t   = 2.6;                  // 2.0 + 0.6 balance-lane web
plate_h   = pocket_depth + floor_t;              // 12.6
wall      = 3;
edge      = wall + pocket_d/2;                   // 16.45 to first center
plate_x   = (cols-1)*pitch + pitch/2 + 2*edge;   // 298.9
plate_y   = (rows-1)*row_p + 2*edge;             // 251.1

// ---- Welding / strips ----
weld_d      = 21;
strip_depth = 1.2;
strip_w     = 12;
br_step     = 0.2;   // sacrificial bridge stage height = slicer layer height

// ---- Balance-lead lanes ----
lane_w = 2.5;
lane_d = 1.8;

// ---- Sectioning ----
seam_gap = 0.15;   // total clearance per butt seam
key_gap  = 0.25;   // total clearance around dovetail keys
kx = (key_gap - seam_gap)/2;   // extra pre-offset so keys end up at key_gap
A_cb = [[0,2], [3,9]];   // A-face piece column ranges (incl.)
A_rb = [[0,2], [3,9]];   // A-face piece row ranges
B_cb = [[0,4], [5,9]];
B_rb = [[0,4], [5,9]];
function seam_c(p) = p == "A" ? 2 : 4;   // seam between cols c|c+1
function seam_j(p) = p == "A" ? 2 : 4;   // seam between rows j|j+1

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

// ---- Interior tie bolts (M4, through interstice columns) ----
// iLow(i,j): interstice between cells (i,j),(i+1,j) and the row-j+1 cell
// between them. Three distinct groups at each of these — see header.
mid_bolt_d  = 4.3;
function iLow(i, j) = [cx(i, j) + pitch/2, cy(j) + row_p/3];
mid_rod_pos = [
    iLow(1, 3),   // ( 72.45,  97.28) corridor 3|4 west (j9 lane is east)
    iLow(1, 7),   // ( 72.45, 194.28) corridor 7|8 west
    iLow(6, 1),   // (212.45,  48.78) corridor 1|2 east (j5 lane is west)
    iLow(6, 5),   // (212.45, 145.78) corridor 5|6 east (j13 lane is west)
    iLow(6, 7)];  // (212.45, 194.28) corridor 7|8 east

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

// Weld-access window with stepped sacrificial bridges (see header). Pack
// coords: floor spans z 0..floor_t, so the stage nearest floor_t is the
// FIRST ceiling layer printed (weld-face-up flips z). Slot runs along X.
module weld_window(px, py) {
    // round window, full depth minus the two bridge stages
    translate([px, py, -1])
        cylinder(d=weld_d, h=floor_t - 2*br_step + 1);
    // stage 2: square opening — its edge strips bridge onto the slot slivers
    translate([px, py, floor_t - 2*br_step - 0.01])
        linear_extrude(br_step + 0.02)
            intersection() { square(weld_d, center=true); circle(d=pocket_d); }
    // stage 1: slot opening — circle-segment slivers bridge the pocket,
    // anchored on the pocket wall (extends into the pocket void above)
    translate([px, py, floor_t - br_step])
        linear_extrude(br_step + 0.5)
            intersection() {
                square([pocket_d + 2, weld_d], center=true);
                circle(d=pocket_d);
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
            // Entry chamfer — small lead-in only. At full 28mm pitch a wide
            // chamfer's rims overlap and shred the bed-side first layer
            // (this is the pocket-mouth face, printed DOWN); +0.6 keeps a
            // 0.5mm rim wall that extrudes cleanly.
            translate([p[0], p[1], plate_h - 1])
                cylinder(d1=pocket_d, d2=pocket_d + 0.6, h=1.01);
            // Weld-access window (stepped bridges)
            weld_window(p[0], p[1]);
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

        for (p = mid_rod_pos)
            translate([p[0], p[1], -1]) cylinder(d=mid_bolt_d, h=plate_h + 2);
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

// ---- Dovetail keys ----
// Flared trapezoids inscribed in the seam interstices (see header). Male
// side is pre-shrunk by kx, sockets pre-grown by kx; the global
// offset(-seam_gap/2) in piece() then brings total key clearance to key_gap.
hkey_prof = [[-0.9,-1.8], [0.9,-1.8], [1.4,1.8], [-1.4,1.8]];   // points +Y
vkey_prof = [[-1.6,-0.8], [1.6,-1.3], [1.6,1.3], [-1.6,0.8]];   // points +X

// Row-seam keys at HIGH vertices (k odd in hseam_pts). k=5 (A) / k=9 (B)
// sit on the col-seam crossing; middle picks thinned to ~56mm spacing.
A_hk = [1, 3, 7, 11, 15, 17];
B_hk = [1, 5, 7, 11, 15, 17];
function hkey_ctrs(p) = let (j = seam_j(p),
    xa = edge + ((j % 2 == 0) ? 0 : pitch/2) + pitch/2)
    [for (k = (p == "A" ? A_hk : B_hk)) [xa + k*pitch/2, cy(j) + 2*row_p/3]];

// Col-seam keys at top-of-run corners (x_j, cy(j)+row_p/3). j=2 (A) /
// j=4 (B) are the row-seam crossing corners — skipped.
A_vk = [0, 3, 4, 7, 8];
B_vk = [0, 3, 6, 7, 8];
function vkey_ctrs(p) = let (c = seam_c(p),
    xL = edge + pitch/2 + c*pitch, xR = xL + pitch/2)
    [for (j = (p == "A" ? A_vk : B_vk)) [(j % 2 == 0) ? xL : xR, cy(j) + row_p/3]];

module keys2d(ctrs, prof, grow)
    for (c = ctrs) translate(c) offset(delta=grow) polygon(prof);

// ---- Piece masks (2D, pack coords) ----
// Lower piece owns row-seam keys; left piece owns col-seam keys.
module ymask(p, rb) difference() {
    union() {
        polygon(concat(
            rb[0] == 0      ? [[-2, -2], [plate_x + 2, -2]] : hseam_pts(rb[0] - 1),
            rb[1] == rows-1 ? [[plate_x + 2, plate_y + 2], [-2, plate_y + 2]]
                            : rev(hseam_pts(rb[1]))));
        if (rb[1] != rows-1) keys2d(hkey_ctrs(p), hkey_prof, -kx);
    }
    if (rb[0] != 0) keys2d(hkey_ctrs(p), hkey_prof, +kx);
}

module xmask(p, cb) difference() {
    union() {
        polygon(concat(
            cb[1] == cols-1 ? [[plate_x + 2, -2], [plate_x + 2, plate_y + 2]]
                            : vseam_pts(cb[1]),
            cb[0] == 0      ? [[-2, plate_y + 2], [-2, -2]] : rev(vseam_pts(cb[0] - 1))));
        if (cb[1] != cols-1) keys2d(vkey_ctrs(p), vkey_prof, -kx);
    }
    if (cb[0] != 0) keys2d(vkey_ctrs(p), vkey_prof, +kx);
}

module piece(pattern, cb, rb) {
    intersection() {
        pack_face(pattern);
        translate([0, 0, -1]) linear_extrude(plate_h + 3)
            offset(delta=-seam_gap/2) ymask(pattern, rb);
        translate([0, 0, -1]) linear_extrude(plate_h + 3)
            offset(delta=-seam_gap/2) xmask(pattern, cb);
    }
}

module sectioned_face(pattern, sep=8) {
    cbs = pattern == "A" ? A_cb : B_cb;
    rbs = pattern == "A" ? A_rb : B_rb;
    for (ci = [0:len(cbs)-1], ri = [0:len(rbs)-1])
        translate([ci*sep, ri*sep, 0]) piece(pattern, cbs[ci], rbs[ri]);
}

// Assembly handedness: the hex lattice isn't mirror-symmetric, so the A
// plate is modeled as a true mirror of the B-style geometry — this defines
// the correct physical part, independent of how it's laid on the bed.
module oriented(pattern) {
    if (pattern == "A")
        translate([plate_x, 0, 0]) mirror([1, 0, 0]) children();
    else
        children();
}

// PRINT ORIENTATION (weld-face-UP, since 006 v2): pocket mouths on the bed.
// The weld face carries almost all the recessed detail; printed down it
// left the 1.4mm floor bridging across those recesses everywhere. Face-up,
// every recess is a clean top-surface pocket. Rigid 180° flip about X, NOT
// a mirror, so oriented()'s A/B handedness is unchanged. Use a brim: bed
// contact is the pocket-wall honeycomb + solid frame, not a full face.
module printflip() translate([0, plate_y, plate_h]) rotate([180, 0, 0]) children();

module holder_face(pattern)               oriented(pattern) pack_face(pattern);
module holder_sectioned(pattern, sep=8)   printflip() oriented(pattern) sectioned_face(pattern, sep);
module holder_piece(pattern, ci, ri)      printflip() oriented(pattern)
    piece(pattern, (pattern == "A" ? A_cb : B_cb)[ci],
                   (pattern == "A" ? A_rb : B_rb)[ri]);

if (mode == "full")           holder_face(pattern);
else if (mode == "sectioned") holder_sectioned(pattern);
else                          holder_piece(pattern, piece_c, piece_r);
