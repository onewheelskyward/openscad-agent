// dropout_gauge_001.scad
// Dropout alignment gauge cup — print 2 (PETG, 100% infill, face down).
//
// Poor-man's Park FFG-2: fix a short M10 threaded-rod stub in each dropout
// with nuts, slide a cup onto each stub face-inward, bring the cups
// together in the middle and read the gap:
//   - even hairline gap all around, rims concentric  -> dropouts aligned
//   - wedge-shaped gap        -> faces not parallel (toed in/out)
//   - rims offset             -> dropouts not on a common axis
//
// The reading face is a narrow raised rim (not the full disc) so the gap
// is crisp and bed-flat. Print face down on a smooth sheet. The long bore
// rides the rod threads; if it binds, bump `bore` by 0.1.

$fn = 128;

bore     = 10.2;  // snug over M10 thread crests (~9.9)
face_od  = 28;    // rim outer diameter
rim_w    = 2.5;   // reading-rim width
face_t   = 3;     // face disc thickness
relief   = 0.6;   // face recess inside the rim
body_d   = 16;    // barrel around the bore
body_l   = 15;    // barrel length behind the face (steadies the cup)

difference() {
    union() {
        cylinder(d=face_od, h=face_t);
        cylinder(d=body_d, h=face_t + body_l);
    }

    // bore
    translate([0, 0, -1]) cylinder(d=bore, h=face_t + body_l + 2);

    // face relief: only the outer rim contacts/reads
    translate([0, 0, -0.01])
        cylinder(d=face_od - 2*rim_w, h=relief);
}
