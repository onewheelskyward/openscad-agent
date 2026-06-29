// Coffee Table Caddy — v007
// Every hole individually configurable: shape, x size, y size, depth,
// and column/row SPANNING (merged cells).
//
// `cells` is a list of rows (front row first); each row is a list of cells:
//     [shape, size_x, size_y, depth, span_cols, span_rows]
//   shape : "s" square, "r" round, "-" no pocket / covered by a span
//   size_x, size_y : pocket footprint in mm (round uses min of the two
//                    as its diameter). Omit to use cell_x / cell_y.
//   depth : pocket depth in mm. Omit to use pocket_depth.
//   span_cols, span_rows : how many grid cells the pocket spans
//                    (default 1). Put "-" in the covered cells.
//
// Column widths and row depths auto-size to the largest pocket in them
// (a spanning pocket contributes its size split across the cells it
// spans), and every pocket is centered over its spanned region.
//
// If cells = [], a uniform cols x rows grid of the global defaults is used.

/* [Per-hole layout] */
cells = [
    // row 1: 70x102 slot spanning rows 1-2 | 34x36 slot
    [ ["s", 70, 102, 35, 1, 2],  ["s", 34, 36] ],
    // row 2: covered by the span above | 66x32 slot
    [ ["-"],                     ["s", 66, 32] ],
    // row 3: 35mm round | 61x35 slot
    [ ["r", 35, 35],             ["s", 61, 35] ],
    // row 4: 35mm round | 29x31 slot
    [ ["r", 35, 35],             ["s", 29, 31] ]
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
wall    = 4;
floor_h = 4;
body_corner = 10;

/* [Extras] */
// Diamond drain grid cut through each pocket floor (0 size = none)
drain_size   = 8;    // diamond width, corner to corner (mm)
drain_pitch  = 14;   // center-to-center spacing of the lattice (mm)
drain_margin = 6;    // solid border kept inside each pocket edge (mm)

/* [Quality] */
$fn = 96;

// ---- normalize the cells spec --------------------------------------------
default_char = shape == "round" ? "r" : "s";

grid = len(cells) > 0
    ? cells
    : [for (r = [0:rows-1]) [for (c = [0:cols-1]) [default_char]]];

n_rows = len(grid);
n_cols = max([for (row = grid) len(row)]);

// accessors with defaults; missing cells in short rows become "-"
function cel(r, c)   = c < len(grid[r]) ? grid[r][c] : ["-"];
function csh(r, c)   = cel(r, c)[0];
function csx(r, c)   = len(cel(r,c)) > 1 && cel(r,c)[1] != undef ? cel(r,c)[1] : cell_x;
function csy(r, c)   = len(cel(r,c)) > 2 && cel(r,c)[2] != undef ? cel(r,c)[2] : cell_y;
function cdp(r, c)   = len(cel(r,c)) > 3 && cel(r,c)[3] != undef ? cel(r,c)[3] : pocket_depth;
function spc(r, c)   = len(cel(r,c)) > 4 && cel(r,c)[4] != undef ? cel(r,c)[4] : 1;
function spr(r, c)   = len(cel(r,c)) > 5 && cel(r,c)[5] != undef ? cel(r,c)[5] : 1;
function used(r, c)  = csh(r, c) == "s" || csh(r, c) == "r";

// size a pocket demands from EACH cell it spans: subtract the walls it
// absorbs, then split evenly across the spanned cells
function need_x(r, c) = (csx(r,c) - (spc(r,c) - 1) * wall) / spc(r,c);
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
function span_w(c, sc) = sum([for (i = [c:1:c+sc-1]) col_w[i]]) + (sc - 1) * wall;
function span_d(r, sr) = sum([for (i = [r:1:r+sr-1]) row_d[i]]) + (sr - 1) * wall;
function cx(r, c) = wall + sum([for (i = [0:1:c-1]) col_w[i] + wall])
                    + span_w(c, spc(r,c)) / 2;
function cy(r, c) = wall + sum([for (i = [0:1:r-1]) row_d[i] + wall])
                    + span_d(r, spr(r,c)) / 2;

W = sum(col_w) + (n_cols + 1) * wall;
D = sum(row_d) + (n_rows + 1) * wall;
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

difference() {
    rounded_slab(W, D, H, body_corner);
    for (r = [0:n_rows-1], c = [0:n_cols-1])
        if (used(r, c))
            translate([cx(r, c), cy(r, c), H - cdp(r, c)])
                pocket(csh(r,c), csx(r,c), csy(r,c), cdp(r,c),
                       H - cdp(r, c));
}
