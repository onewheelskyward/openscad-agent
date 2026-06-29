// Coffee Table Caddy — v003
// Every hole individually configurable: shape, x size, y size, depth.
//
// `cells` is a list of rows (front row first); each row is a list of cells:
//     [shape, size_x, size_y, depth]
//   shape : "s" square, "r" round, "-" no pocket (solid block)
//   size_x, size_y : pocket footprint in mm (round uses min of the two
//                    as its diameter). Omit to use cell_x / cell_y.
//   depth : pocket depth in mm. Omit to use pocket_depth.
//
// Column widths and row depths auto-size to the largest pocket in them,
// and every pocket is centered in its grid cell.
//
// If cells = [], a uniform cols x rows grid of the global defaults is used.

/* [Per-hole layout] */
cells = [
    // front row: glass holder, two upright remote slots
    [ ["r", 85, 85],      ["s", 30, 85], ["s", 30, 85] ],
    // back row: shallow coaster tray, spare slot, round pen cup
    [ ["s", 85, 50, 25],  ["s", 30, 50], ["r", 30, 30] ]
];

/* [Defaults (used for omitted values / empty cells list)] */
cols = 3;
rows = 2;
shape  = "square";   // ["square", "round"]
cell_x = 58;
cell_y = 58;
pocket_depth  = 65;

/* [Pockets] */
pocket_corner = 8;   // corner radius for square pockets
chamfer = 2.5;       // entry chamfer (0 = none)

/* [Body] */
wall    = 4;
floor_h = 4;
body_corner = 10;

/* [Extras] */
drain_d = 0;         // drain hole diameter per pocket (0 = none)

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
function used(r, c)  = csh(r, c) == "s" || csh(r, c) == "r";

// column widths / row depths: max pocket size in that column / row
col_w = [for (c = [0:n_cols-1])
            max([for (r = [0:n_rows-1]) used(r,c) ? csx(r,c) : 0])];
row_d = [for (r = [0:n_rows-1])
            max([for (c = [0:n_cols-1]) used(r,c) ? csy(r,c) : 0])];

function sum(v, i = 0) = i >= len(v) ? 0 : v[i] + sum(v, i + 1);

// center of grid cell (r, c)
function cx(c) = wall + sum([for (i = [0:1:c-1]) col_w[i] + wall]) + col_w[c]/2;
function cy(r) = wall + sum([for (i = [0:1:r-1]) row_d[i] + wall]) + row_d[r]/2;

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

// pocket cutter, origin at the pocket's own floor level
module pocket(s, px, py, dp) {
    linear_extrude(dp + 1) pocket_2d(s, px, py);
    if (chamfer > 0) {
        grow = (min(px, py) + 2*chamfer) / min(px, py);
        translate([0, 0, dp - chamfer])
            linear_extrude(chamfer + 1, scale = grow)
                pocket_2d(s, px, py);
    }
    if (drain_d > 0)
        translate([0, 0, -floor_h - 1])
            cylinder(h = floor_h + 2, d = drain_d);
}

difference() {
    rounded_slab(W, D, H, body_corner);
    for (r = [0:n_rows-1], c = [0:n_cols-1])
        if (used(r, c))
            translate([cx(c), cy(r), H - cdp(r, c)])
                pocket(csh(r,c), csx(r,c), csy(r,c), cdp(r,c));
}
