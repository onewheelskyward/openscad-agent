// Framing Wall - 9' x 16' with 29"x45" window (left) and 5'x7.5' door (right)
// Units: inches — v002: boards inset by EPS to show outlines

// Wall dimensions
WALL_W = 192;   // 16'
WALL_H = 108;   // 9'

// 2x4 actual dimensions
LT = 1.5;
LW = 3.5;

// Visual gap between boards (inset on each face)
EPS = 0.25;

OC = 16;

// Window rough opening
WIN_W = 29;
WIN_H = 45;
WIN_L = 42;
WIN_SH = 36;

// Door rough opening
DOOR_W = 60;
DOOR_H = 90;
DOOR_L = 102;

// Window derived
WKL = WIN_L - 2*LT;
WJL = WIN_L - LT;
WJR = WIN_L + WIN_W;
WKR = WIN_L + WIN_W + LT;

W_SILL_Z = WIN_SH;
W_HDR_Z  = WIN_SH + LT + WIN_H;

// Door derived
DKL = DOOR_L - 2*LT;
DJL = DOOR_L - LT;
DJR = DOOR_L + DOOR_W;
DKR = DOOR_L + DOOR_W + LT;

D_HDR_Z = DOOR_H;

STUD_H = WALL_H - LT - 2*LT;

// --- Primitives with EPS inset ---

module vstud(x_pos, z_bot, height) {
    translate([x_pos + EPS, EPS, z_bot + EPS])
        cube([LT - 2*EPS, LW - 2*EPS, height - 2*EPS]);
}

module hbeam(x_pos, z_bot, width) {
    translate([x_pos + EPS, EPS, z_bot + EPS])
        cube([width - 2*EPS, LW - 2*EPS, LT - 2*EPS]);
}

// --- Plates ---

module bottom_plate() {
    hbeam(0, 0, DJL);
    hbeam(DJR + LT, 0, WALL_W - DJR - LT);
}

module top_plate() {
    hbeam(0, WALL_H - 2*LT, WALL_W);
    hbeam(0, WALL_H - LT,   WALL_W);
}

// --- Field studs ---

module field_studs() {
    vstud(0, LT, STUD_H);
    vstud(WALL_W - LT, LT, STUD_H);

    for (x = [OC : OC : WALL_W - LT]) {
        in_win  = (x >= WKL - 0.01) && (x <= WKR + 0.01);
        in_door = (x >= DKL - 0.01) && (x <= DKR + 0.01);
        if (!in_win && !in_door)
            vstud(x, LT, STUD_H);
    }
}

// --- Window framing ---

module window_framing() {
    vstud(WKL, LT, STUD_H);
    vstud(WKR, LT, STUD_H);

    vstud(WJL, LT, WIN_SH - LT);
    vstud(WJR, LT, WIN_SH - LT);

    hbeam(WJL, W_SILL_Z, WIN_W + 2*LT);

    hbeam(WKL, W_HDR_Z,       WIN_W + 4*LT);
    hbeam(WKL, W_HDR_Z + LT,  WIN_W + 4*LT);

    z_ahdr = W_HDR_Z + 2*LT;
    vstud(WJL, z_ahdr, WALL_H - 2*LT - z_ahdr);
    vstud(WJR, z_ahdr, WALL_H - 2*LT - z_ahdr);

    for (x = [WJL + OC : OC : WJR]) {
        if (x + LT <= WJR + 0.01) {
            vstud(x, LT, WIN_SH - LT);
            z_ahdr2 = W_HDR_Z + 2*LT;
            vstud(x, z_ahdr2, WALL_H - 2*LT - z_ahdr2);
        }
    }
}

// --- Door framing ---

module door_framing() {
    vstud(DKL, LT, STUD_H);
    vstud(DKR, LT, STUD_H);

    vstud(DJL, 0, D_HDR_Z);
    vstud(DJR, 0, D_HDR_Z);

    hbeam(DKL, D_HDR_Z,       DOOR_W + 4*LT);
    hbeam(DKL, D_HDR_Z + LT,  DOOR_W + 4*LT);

    z_ahdr = D_HDR_Z + 2*LT;
    for (x = [DJL + OC : OC : DJR]) {
        if (x + LT <= DJR + 0.01)
            vstud(x, z_ahdr, WALL_H - 2*LT - z_ahdr);
    }
}

// --- Assembly ---

color("BurlyWood") union() {
    bottom_plate();
    top_plate();
    field_studs();
    window_framing();
    door_framing();
}
