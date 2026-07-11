// Cherry Pit Lid v002 - cleaner geometry, no z-fighting
// Sits on standard coffee mug ~85mm outer rim diameter

$fn = 80;

mug_od      = 85;    // mug outer rim diameter
clearance   = 0.6;   // fit clearance over rim
wall        = 3.5;   // lid wall thickness
rim_depth   = 10;    // how deep the collar drops over the mug rim
lid_thick   = 8;     // total height of the lid top section
pit_hole_d  = 18;    // center hole for cherry pit
bowl_r      = 22;    // radius of finger bowl recess
bowl_depth  = 5;     // depth of bowl recess

outer_d = mug_od + wall * 2;

difference() {
    // Solid outer shell: collar + lid top as one piece
    cylinder(d = outer_d, h = rim_depth + lid_thick);

    // Bore out the inside of the collar (fits over mug rim)
    translate([0, 0, lid_thick])
        cylinder(d = mug_od + clearance, h = rim_depth + 1);

    // Bowl recess on top: a sphere segment cut into the top face
    translate([0, 0, rim_depth + lid_thick + bowl_r - bowl_depth])
        sphere(r = bowl_r);

    // Pit hole straight through the center
    cylinder(d = pit_hole_d, h = rim_depth + lid_thick + 1);
}
