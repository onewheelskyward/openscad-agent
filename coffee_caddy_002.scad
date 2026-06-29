// Coffee Table Caddy — v002
// Parametric organizer: rows x columns of pockets, square or round,
// globally or per-cell. Chamfered openings, optional drain holes.
//
// Per-cell layout: one string per row (front row first), one char per column:
//   's' = square pocket   'r' = round pocket   '.' = use global `shape`
// Leave layout = [] to use the global shape everywhere.

/* [Grid] */
cols = 3;
rows = 2;
layout = ["rss", "rss"];   // example: round column for glasses, squares for remotes

/* [Pockets] */
shape  = "square";    // ["square", "round"] global default
cell_x = 58;          // pocket size in x (round uses the smaller of x/y)
cell_y = 58;          // pocket size in y
pocket_depth  = 65;   // remotes stand upright at ~60+
pocket_corner = 8;    // corner radius for square pockets
chamfer = 2.5;        // entry chamfer at pocket openings (0 = none)

/* [Body] */
wall    = 4;          // wall between/around pockets
floor_h = 4;          // solid floor
body_corner = 10;     // outer corner radius

/* [Extras] */
drain_d = 0;          // drain/cleanout hole diameter per pocket (0 = none)

/* [Quality] */
$fn = 96;

// ---- derived ----
W = cols * cell_x + (cols + 1) * wall;
D = rows * cell_y + (rows + 1) * wall;
H = pocket_depth + floor_h;
echo(str("Outer size: ", W, " x ", D, " x ", H, " mm"));

function cell_shape(r, c) =
    (len(layout) > r && len(layout[r]) > c && layout[r][c] != ".")
        ? (layout[r][c] == "r" ? "round" : "square")
        : shape;

module rounded_slab(w, d, h, rad)
    hull()
        for (x = [rad, w - rad], y = [rad, d - rad])
            translate([x, y, 0]) cylinder(h = h, r = rad);

// centered 2D pocket profile
module pocket_2d(s) {
    if (s == "round")
        circle(d = min(cell_x, cell_y));
    else
        offset(r = pocket_corner)
            square([cell_x - 2*pocket_corner, cell_y - 2*pocket_corner],
                   center = true);
}

// pocket cutter: straight bore + entry chamfer, origin at pocket floor
module pocket(s) {
    linear_extrude(pocket_depth + 1) pocket_2d(s);
    if (chamfer > 0) {
        grow = (min(cell_x, cell_y) + 2*chamfer) / min(cell_x, cell_y);
        translate([0, 0, pocket_depth - chamfer])
            linear_extrude(chamfer + 1, scale = grow)
                pocket_2d(s);
    }
    if (drain_d > 0)
        translate([0, 0, -floor_h - 1])
            cylinder(h = floor_h + 2, d = drain_d);
}

difference() {
    rounded_slab(W, D, H, body_corner);
    for (c = [0 : cols - 1], r = [0 : rows - 1])
        translate([wall + cell_x/2 + c * (cell_x + wall),
                   wall + cell_y/2 + r * (cell_y + wall),
                   floor_h])
            pocket(cell_shape(r, c));
}
