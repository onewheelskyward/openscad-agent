// Coffee Table Caddy — v015
// v014, but the three back-row holes are separated by 15mm between each
// (round pill -> floss -> 29x31 toothbrush slot). At the current 168mm width
// the trio nearly fills the body: the square lands ~3.8mm from the right wall
// and the round keeps ~16mm to the left, so the margins are intentionally
// lopsided (width was kept fixed).
//
// `cells` is a list of rows (front row first); each row is a list of cells:
//     [shape, size_x, size_y, depth, span_cols, span_rows, offset_x, offset_y]
//   shape : "s" square, "r" round, "-" no pocket / covered by a span
//   size_x, size_y : pocket footprint in mm (round uses min of the two
//                    as its diameter). Omit to use cell_x / cell_y.
//   depth : pocket depth in mm. Omit to use pocket_depth.
//   span_cols, span_rows : how many grid cells the pocket spans
//                    (default 1). Put "-" in the covered cells.
//   offset_x, offset_y : nudge the pocket off-center within its cell/span
//                    (default 0,0). Used here to stagger the round holes.
//
// Column widths and row depths auto-size to the largest pocket in them
// (a spanning pocket contributes its size split across the cells it
// spans), and every pocket is centered (plus its offset) over its
// spanned region.
//
// If cells = [], a uniform cols x rows grid of the global defaults is used.

/* [Per-hole layout] */
cells = [
    // row 1: 70x102 slot spanning rows 1-2 | 34x36 slot
    [ ["s", 70, 102, 35, 1, 2],  ["s", 34, 36] ],
    // row 2: covered by the span above | 66x32 slot
    [ ["-"],                     ["s", 66, 32] ],
    // row 3: 35mm round, nudged +x | 61x35 slot
    [ ["r", 35, 35, 35, 1, 1, 12, 0],  ["s", 61, 35] ],
    // row 4: 35mm round, nudged -x (stagger vs. row 3 -> diagonal look)
    //        | 29x31 slot pushed +9 -> evenly spaced past round + floss
    [ ["r", 35, 35, 35, 1, 1, -12, 0], ["s", 29, 31, 35, 1, 1, 25.33, 0] ]
];

/* [Defaults (used for omitted values / empty cells list)] */
cols = 3;
rows = 2;
shape  = "square";   // ["square", "round"]
cell_x = 58;
cell_y = 58;
pocket_depth  = 35;

/* [Pockets] */
pocket_corner = 8;   // corner radius for square pockets
chamfer = 2.5;       // entry chamfer (0 = none)

/* [Body] */
wall    = 4;         // base wall thickness / minimum horizontal gap
row_gap = 10;        // vertical gap between rows (front-to-back breathing room)
width_pad = 20;      // extra width, spread evenly across the 3 vertical gaps
floor_h = 4;
body_corner = 10;

/* [Extras] */
// Diamond drain grid cut through each pocket floor (0 size = none)
drain_size   = 8;    // diamond width, corner to corner (mm)
drain_pitch  = 14;   // center-to-center spacing of the lattice (mm)
drain_margin = 6;    // solid border kept inside each pocket edge (mm)

/* [Front strip] */
extra_length = 0;    // front margin (0 = none; space redistributed to row_gap)
// Floss slot sized for a Glide floss container (~52 x 40 x 17mm) standing
// on edge, plus ~2mm clearance all round. Lives in the back row now.
floss_l      = 54;   // slot length  (x, container's 52mm width + clearance)
floss_w      = 19;   // slot width   (y, container's 17mm thickness + clr)
floss_depth  = 30;   // slot depth   (container ~40mm tall, ~10mm proud)
floss_corner = 4;    // floss slot corner radius

/* [Quality] */
$fn = 96;

// ---- normalize the cells spec --------------------------------------------
default_char = shape == "round" ? "r" : "s";

grid = len(cells) > 0
    ? cells
    : [for (r = [0:rows-1]) [for (c = [0:cols-1]) [default_char]]];

n_rows = len(grid);
n_cols = max([for (row = grid) len(row)]);

// horizontal gap = base wall plus an even share of the extra width across
// the (n_cols + 1) vertical gaps (two borders + the inter-column channels).
hgap = wall + width_pad / (n_cols + 1);

// accessors with defaults; missing cells in short rows become "-"
function cel(r, c)   = c < len(grid[r]) ? grid[r][c] : ["-"];
function csh(r, c)   = cel(r, c)[0];
function csx(r, c)   = len(cel(r,c)) > 1 && cel(r,c)[1] != undef ? cel(r,c)[1] : cell_x;
function csy(r, c)   = len(cel(r,c)) > 2 && cel(r,c)[2] != undef ? cel(r,c)[2] : cell_y;
function cdp(r, c)   = len(cel(r,c)) > 3 && cel(r,c)[3] != undef ? cel(r,c)[3] : pocket_depth;
function spc(r, c)   = len(cel(r,c)) > 4 && cel(r,c)[4] != undef ? cel(r,c)[4] : 1;
function spr(r, c)   = len(cel(r,c)) > 5 && cel(r,c)[5] != undef ? cel(r,c)[5] : 1;
function cox(r, c)   = len(cel(r,c)) > 6 && cel(r,c)[6] != undef ? cel(r,c)[6] : 0;
function coy(r, c)   = len(cel(r,c)) > 7 && cel(r,c)[7] != undef ? cel(r,c)[7] : 0;
function used(r, c)  = csh(r, c) == "s" || csh(r, c) == "r";

// size a pocket demands from EACH cell it spans: subtract the walls it
// absorbs, then split evenly across the spanned cells
function need_x(r, c) = (csx(r,c) - (spc(r,c) - 1) * hgap) / spc(r,c);
function need_y(r, c) = (csy(r,c) - (spr(r,c) - 1) * wall) / spr(r,c);

// does the pocket anchored at (r0, c0) cover cell (r, c)?
function covers(r0, c0, r, c) =
    used(r0, c0) && r >= r0 && r < r0 + spr(r0, c0)
                 && c >= c0 && c < c0 + spc(r0, c0);

// column widths / row depths: max demand from any pocket touching them
col_w = [for (c = [0:n_cols-1])
            max([for (r0 = [0:n_rows-1], c0 = [0:n_cols-1])
                    covers(r0, c0, r0, c) ? need_x(r0, c0) : 0])];
row_d = [for (r = [0:n_rows-1])
            max([for (r0 = [0:n_rows-1], c0 = [0:n_cols-1])
                    covers(r0, c0, r, c0) ? need_y(r0, c0) : 0])];

function sum(v, i = 0) = i >= len(v) ? 0 : v[i] + sum(v, i + 1);

// center of the region spanned by a pocket anchored at (r, c)
function span_w(c, sc) = sum([for (i = [c:1:c+sc-1]) col_w[i]]) + (sc - 1) * hgap;
function span_d(r, sr) = sum([for (i = [r:1:r+sr-1]) row_d[i]]) + (sr - 1) * row_gap;
function cx(r, c) = hgap + sum([for (i = [0:1:c-1]) col_w[i] + hgap])
                    + span_w(c, spc(r,c)) / 2 + cox(r, c);
function cy(r, c) = extra_length + wall + sum([for (i = [0:1:r-1]) row_d[i] + row_gap])
                    + span_d(r, spr(r,c)) / 2 + coy(r, c);

W = sum(col_w) + (n_cols + 1) * hgap;
D = sum(row_d) + 2 * wall + (n_rows - 1) * row_gap + extra_length;
max_depth = max([for (r = [0:n_rows-1], c = [0:n_cols-1])
                    used(r,c) ? cdp(r,c) : 0]);
H = max_depth + floor_h;

echo(str("Outer size: ", W, " x ", D, " x ", H, " mm"));

// ---- geometry --------------------------------------------------------------
module rounded_slab(w, d, h, rad)
    hull()
        for (x = [rad, w - rad], y = [rad, d - rad])
            translate([x, y, 0]) cylinder(h = h, r = rad);

module pocket_2d(s, px, py) {
    if (s == "r")
        circle(d = min(px, py));
    else {
        rr = min(pocket_corner, min(px, py)/2 - 0.01);
        offset(r = rr) square([px - 2*rr, py - 2*rr], center = true);
    }
}

// 2D diamond lattice covering a px x py area (two interleaved sets)
module diamonds_2d(px, py) {
    nx = ceil(px / 2 / drain_pitch) + 1;
    ny = ceil(py / 2 / drain_pitch) + 1;
    edge = drain_size / sqrt(2);   // square edge for the given diagonal
    for (i = [-nx:nx], j = [-ny:ny], k = [0, 1])
        translate([(i + k/2) * drain_pitch, (j + k/2) * drain_pitch])
            rotate(45) square(edge, center = true);
}

// pocket cutter, origin at the pocket's own floor level.
// floor_below = thickness of material under THIS pocket's floor.
module pocket(s, px, py, dp, floor_below) {
    linear_extrude(dp + 1) pocket_2d(s, px, py);
    if (chamfer > 0) {
        grow = (min(px, py) + 2*chamfer) / min(px, py);
        translate([0, 0, dp - chamfer])
            linear_extrude(chamfer + 1, scale = grow)
                pocket_2d(s, px, py);
    }
    if (drain_size > 0)
        translate([0, 0, -floor_below - 1])
            linear_extrude(floor_below + 2)
                intersection() {
                    offset(r = -drain_margin) pocket_2d(s, px, py);
                    diamonds_2d(px, py);
                }
}

// narrow slot in the new front strip, sized to hold a dental floss
// container/pick; no drain holes (too shallow/narrow to need one).
module floss_slot(fl, fw, dp) {
    rr = min(floss_corner, min(fl, fw)/2 - 0.01);
    linear_extrude(dp + 1)
        offset(r = rr) square([fl - 2*rr, fw - 2*rr], center = true);
    if (chamfer > 0) {
        grow = (min(fl, fw) + 2*chamfer) / min(fl, fw);
        translate([0, 0, dp - chamfer])
            linear_extrude(chamfer + 1, scale = grow)
                offset(r = rr) square([fl - 2*rr, fw - 2*rr], center = true);
    }
}

// floss slot: back row. Space the three holes (round | floss | rect) with
// four equal gaps: wall -> round -> floss -> rect -> wall.
// floss sits floss_gap (15mm) to the right of the round pill hole's edge.
// The 29x31 slot's +25.33 x-offset (in cells) puts its left edge 15mm past
// the floss, giving equal 15mm gaps on both sides.
floss_gap = 15;
floss_cx = (cx(3,0) + csx(3,0)/2) + floss_gap + floss_l/2;
floss_cy = cy(3,0);

difference() {
    rounded_slab(W, D, H, body_corner);
    for (r = [0:n_rows-1], c = [0:n_cols-1])
        if (used(r, c))
            translate([cx(r, c), cy(r, c), H - cdp(r, c)])
                pocket(csh(r,c), csx(r,c), csy(r,c), cdp(r,c),
                       H - cdp(r, c));
    translate([floss_cx, floss_cy, H - floss_depth])
        floss_slot(floss_l, floss_w, floss_depth);
}
