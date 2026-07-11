// Framing Wall - 9' x 16' with 29"x45" window (left) and 5'x7.5' door (right)
// Units: inches

// Wall dimensions
WALL_W = 192;   // 16'
WALL_H = 108;   // 9'

// 2x4 actual dimensions
LT = 1.5;   // thickness
LW = 3.5;   // width / wall depth

// Stud spacing on center
OC = 16;

// Window rough opening
WIN_W = 29;
WIN_H = 45;
WIN_L = 24;   // left edge of RO from wall left
WIN_SH = 36;  // sill z from sub-floor (bottom of sill plate)

// Door rough opening
DOOR_W = 60;  // 5'
DOOR_H = 90;  // 7.5' = 90"
DOOR_L = 112; // left edge of RO from wall left

// --- Derived window positions ---
WKL = WIN_L - 2*LT;        // left king stud x
WJL = WIN_L - LT;          // left jack stud x
WJR = WIN_L + WIN_W;       // right jack stud x
WKR = WIN_L + WIN_W + LT;  // right king stud x

W_SILL_Z = WIN_SH;               // z of sill plate bottom
W_HDR_Z  = WIN_SH + LT + WIN_H;  // z of header bottom (above sill + LT + RO height)

// --- Derived door positions ---
DKL = DOOR_L - 2*LT;
DJL = DOOR_L - LT;
DJR = DOOR_L + DOOR_W;
DKR = DOOR_L + DOOR_W + LT;

D_HDR_Z = DOOR_H;  // jack studs go from z=0 to z=DOOR_H

// Stud height between plates
STUD_H = WALL_H - LT - 2*LT;  // 103.5"

// --- Primitives ---

module vstud(x_pos, z_bot, height) {
    translate([x_pos, 0, z_bot])
        cube([LT, LW, height]);
}

module hbeam(x_pos, z_bot, width) {
    translate([x_pos, 0, z_bot])
        cube([width, LW, LT]);
}

// --- Wall plates ---

module bottom_plate() {
    hbeam(0, 0, DJL);                         // left of door
    hbeam(DJR + LT, 0, WALL_W - DJR - LT);   // right of door
}

module top_plate() {
    hbeam(0, WALL_H - 2*LT, WALL_W);
    hbeam(0, WALL_H - LT,   WALL_W);
}

// --- Field studs at 16" OC, skipping opening zones ---

module field_studs() {
    vstud(0, LT, STUD_H);             // left end stud
    vstud(WALL_W - LT, LT, STUD_H);  // right end stud

    for (x = [OC : OC : WALL_W - LT]) {
        in_win  = (x >= WKL - 0.01) && (x <= WKR + 0.01);
        in_door = (x >= DKL - 0.01) && (x <= DKR + 0.01);
        if (!in_win && !in_door)
            vstud(x, LT, STUD_H);
    }
}

// --- Window framing ---

module window_framing() {
    // King studs (full stud height, rest on bottom plate)
    vstud(WKL, LT, STUD_H);
    vstud(WKR, LT, STUD_H);

    // Lower jack studs (bottom plate to sill)
    vstud(WJL, LT, WIN_SH - LT);
    vstud(WJR, LT, WIN_SH - LT);

    // Sill plate
    hbeam(WJL, W_SILL_Z, WIN_W + 2*LT);

    // Double header
    hbeam(WKL, W_HDR_Z,       WIN_W + 4*LT);
    hbeam(WKL, W_HDR_Z + LT,  WIN_W + 4*LT);

    // Upper jack studs (header to top plate)
    z_ahdr = W_HDR_Z + 2*LT;
    vstud(WJL, z_ahdr, WALL_H - 2*LT - z_ahdr);
    vstud(WJR, z_ahdr, WALL_H - 2*LT - z_ahdr);

    // Cripple studs below sill
    for (x = [WJL + OC : OC : WJR]) {
        if (x + LT <= WJR + 0.01)
            vstud(x, LT, WIN_SH - LT);
    }

    // Cripple studs above header
    z_ahdr = W_HDR_Z + 2*LT;
    for (x = [WJL + OC : OC : WJR]) {
        if (x + LT <= WJR + 0.01)
            vstud(x, z_ahdr, WALL_H - 2*LT - z_ahdr);
    }
}

// --- Door framing ---

module door_framing() {
    // King studs (rest on bottom plate)
    vstud(DKL, LT, STUD_H);
    vstud(DKR, LT, STUD_H);

    // Jack studs (from sub-floor to door header height)
    vstud(DJL, 0, D_HDR_Z);
    vstud(DJR, 0, D_HDR_Z);

    // Double header
    hbeam(DKL, D_HDR_Z,       DOOR_W + 4*LT);
    hbeam(DKL, D_HDR_Z + LT,  DOOR_W + 4*LT);

    // Cripple studs above header
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
