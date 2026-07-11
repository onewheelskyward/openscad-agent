// Cherry Pit Lid - sits on a standard coffee mug, hole in center for pits
// Mug outer rim ~85mm diameter

$fn = 64;

// Dimensions
mug_od      = 85;    // mug outer rim diameter
wall        = 3;     // lid wall thickness
rim_depth   = 8;     // how deep the lid drops over the mug rim
lid_height  = 6;     // thickness of the flat lid top
pit_hole_d  = 18;    // center hole diameter (cherry pit passes through)
funnel_depth = 4;    // depth of funnel recess around hole
bowl_d      = 50;    // diameter of the finger bowl / rest area

// Outer shell that drops over the mug rim
module mug_collar() {
    difference() {
        // Outer cylinder
        cylinder(d = mug_od + wall*2, h = rim_depth + lid_height);
        // Inner bore that fits over mug rim
        translate([0, 0, lid_height])
            cylinder(d = mug_od + 0.5, h = rim_depth + 0.1); // 0.5mm clearance
    }
}

// Flat top with funnel and pit hole
module lid_top() {
    difference() {
        cylinder(d = mug_od + wall*2, h = lid_height);

        // Funnel recess: shallow bowl around the pit hole
        translate([0, 0, lid_height - funnel_depth])
            cylinder(d1 = pit_hole_d, d2 = bowl_d, h = funnel_depth + 0.1);

        // Pit hole through the lid
        cylinder(d = pit_hole_d, h = lid_height + 0.1);
    }
}

union() {
    lid_top();
    mug_collar();
}
