// keyhole_hanger_002.scad
// Two-part wall hanger set for a wooden board.
//
//   Part A - keyhole plate. Carries the load, sets the height,
//            traps the nail head so the board can't be pulled off.
//   Part B - stabilizer plate. Open channel, no retaining lip.
//            Stops the board rotating around A's nail and holds that
//            end flat to the wall. Deliberately forgiving: the nail can
//            sit anywhere in a wide window, so it never fights part A.
//
// Both parts are the same total thickness, so the board sits flat.
//
// Orientation when installed:
//   z = 0        flat face, screwed against the board
//   z = total_t  face toward the wall

$fn = 64;
eps = 0.01;

// "A", "B", or "both" (both = side by side, for preview only)
part = "both";

/* ---- shared stack ---- */
web_t = 3.0;      // solid layer against the wood
cav_t = 4.0;      // nail-head clearance
lip_t = 2.5;      // retaining lip / channel mouth
total_t = web_t + cav_t + lip_t;   // 9.5

corner_r = 3;

/* ---- shared mounting ears ---- */
ear_r      = 6;
ear_t      = 4.0;
screw_d    = 3.6;            // #6 wood screw shank
csink_d    = 7.2;
csink_deep = 1.9;

/* ---- part A: keyhole ---- */
a_body_w = 26;
a_body_h = 34;
a_ear_cx = a_body_w/2 + 5;   // 18
head_d   = 13.0;             // clearance dia for the nail head
shank_w  =  5.0;             // slot width (nail shank + clearance)
hole_y   = -8;               // centre of the big entry opening
slot_y   =  8;               // top of slot = where the nail carries the load

/* ---- part B: stabilizer ---- */
b_body_w  = 36;
b_body_h  = 26;
b_ear_cx  = b_body_w/2 + 5;  // 23
chan_w    = 26;              // lateral tolerance for the second nail
chan_h    = 14;              // vertical tolerance (never load-bearing)

/* ---------------- shared helpers ---------------- */

module rrect2d(w, h, r) {
    offset(r = r) square([w - 2*r, h - 2*r], center = true);
}

module foot2d(body_w, body_h, ear_cx) {
    hull() {
        rrect2d(body_w, body_h, corner_r);
        for (s = [-1, 1]) translate([s * ear_cx, 0]) circle(r = ear_r);
    }
}

// body + ears, before any openings are cut
module blank(body_w, body_h, ear_cx) {
    union() {
        linear_extrude(total_t) rrect2d(body_w, body_h, corner_r);
        linear_extrude(ear_t)   foot2d(body_w, body_h, ear_cx);
    }
}

// countersunk screw holes, heads on the wall-facing side of the ears
module screws(ear_cx) {
    for (s = [-1, 1]) translate([s * ear_cx, 0, 0]) {
        translate([0, 0, -eps])
            cylinder(d = screw_d, h = ear_t + 2*eps);
        translate([0, 0, ear_t - csink_deep])
            cylinder(d1 = screw_d, d2 = csink_d, h = csink_deep + eps);
    }
}

/* ---------------- part A: keyhole plate ---------------- */

// cavity the nail head slides through, behind the lip
module a_cavity2d() {
    hull() {
        translate([0, hole_y]) circle(d = head_d);
        translate([0, slot_y]) circle(d = head_d);
    }
}

// opening cut through the lip: full-size entry hole + narrow slot above it
module a_opening2d() {
    translate([0, hole_y]) circle(d = head_d);
    hull() {
        translate([0, hole_y]) circle(d = shank_w);
        translate([0, slot_y]) circle(d = shank_w);
    }
}

module part_A() {
    difference() {
        blank(a_body_w, a_body_h, a_ear_cx);

        // nail-head cavity (sealed except through the lip opening)
        translate([0, 0, web_t])
            linear_extrude(cav_t) a_cavity2d();

        // keyhole through the lip
        translate([0, 0, web_t + cav_t - eps])
            linear_extrude(lip_t + 2*eps) a_opening2d();

        screws(a_ear_cx);
    }
}

/* ---------------- part B: stabilizer plate ---------------- */

module b_channel2d() {
    r = chan_h / 2;
    hull()
        for (s = [-1, 1]) translate([s * (chan_w/2 - r), 0]) circle(r = r);
}

module part_B() {
    difference() {
        blank(b_body_w, b_body_h, b_ear_cx);

        // open channel straight through cavity + lip, floored by the web
        translate([0, 0, web_t])
            linear_extrude(cav_t + lip_t + eps) b_channel2d();

        screws(b_ear_cx);
    }
}

/* ---------------- output ---------------- */

if (part == "A")    part_A();
else if (part == "B") part_B();
else {
    translate([-28, 0, 0]) part_A();
    translate([ 34, 0, 0]) part_B();
}
