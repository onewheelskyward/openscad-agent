// keyhole_hanger_001.scad
// Keyhole hanger plate: screws to the back of a wooden board,
// drops over a nail head in the wall.
//
// Orientation when installed:
//   z = 0        flat face, screwed against the board
//   z = total_t  lip face, toward the wall
//   big opening at the BOTTOM, slot travels UP (board drops onto the nail)

$fn = 64;
eps = 0.01;

/* ---- plate body ---- */
body_w   = 26;    // width of the thick centre section
body_h   = 34;    // height of the thick centre section
corner_r = 3;

web_t = 3.0;      // solid layer against the wood
cav_t = 4.0;      // nail-head cavity
lip_t = 2.5;      // retaining lip facing the wall
total_t = web_t + cav_t + lip_t;   // 9.5

/* ---- keyhole ---- */
head_d  = 13.0;   // clearance dia for the nail head
shank_w =  5.0;   // slot width (nail shank + clearance)
hole_y  = -8;     // centre of the big entry opening
slot_y  =  8;     // top of slot = where the nail carries the load

/* ---- mounting ears ---- */
ear_cx     = body_w/2 + 5;   // 18
ear_r      = 6;
ear_t      = 4.0;
screw_d    = 3.6;            // #6 wood screw shank
csink_d    = 7.2;
csink_deep = 1.9;

/* ---------------- 2D profiles ---------------- */

module body2d() {
    offset(r = corner_r)
        square([body_w - 2*corner_r, body_h - 2*corner_r], center = true);
}

module foot2d() {
    hull() {
        body2d();
        for (s = [-1, 1]) translate([s * ear_cx, 0]) circle(r = ear_r);
    }
}

// cavity the nail head slides through, behind the lip
module cavity2d() {
    hull() {
        translate([0, hole_y]) circle(d = head_d);
        translate([0, slot_y]) circle(d = head_d);
    }
}

// opening cut through the lip: full-size entry hole + narrow slot above it
module lip_opening2d() {
    translate([0, hole_y]) circle(d = head_d);
    hull() {
        translate([0, hole_y]) circle(d = shank_w);
        translate([0, slot_y]) circle(d = shank_w);
    }
}

/* ---------------- solid ---------------- */

module hanger() {
    difference() {
        union() {
            linear_extrude(total_t) body2d();
            linear_extrude(ear_t)   foot2d();
        }

        // nail-head cavity (sealed except through the lip opening)
        translate([0, 0, web_t])
            linear_extrude(cav_t) cavity2d();

        // keyhole through the lip
        translate([0, 0, web_t + cav_t - eps])
            linear_extrude(lip_t + 2*eps) lip_opening2d();

        // mounting screws, countersunk on the wall-facing side of the ears
        for (s = [-1, 1]) translate([s * ear_cx, 0, 0]) {
            translate([0, 0, -eps])
                cylinder(d = screw_d, h = ear_t + 2*eps);
            translate([0, 0, ear_t - csink_deep])
                cylinder(d1 = screw_d, d2 = csink_d, h = csink_deep + eps);
        }
    }
}

hanger();
