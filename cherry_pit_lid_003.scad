// Cherry Pit Lid v003 - fully concave top, 10mm pit hole
// Sits on standard coffee mug ~85mm outer rim diameter

$fn = 80;

mug_od      = 85;
clearance   = 0.6;
wall        = 3.5;
rim_depth   = 10;
lid_thick   = 8;
pit_hole_d  = 10;

outer_d = mug_od + wall * 2;
outer_r = outer_d / 2;

// Sphere radius that makes the bowl span the full lid diameter
// and dip down by lid_thick - 2mm (leaving 2mm floor at edge)
bowl_depth  = lid_thick - 2;
bowl_r      = (outer_r * outer_r + bowl_depth * bowl_depth) / (2 * bowl_depth);

difference() {
    cylinder(d = outer_d, h = rim_depth + lid_thick);

    // Collar bore
    translate([0, 0, lid_thick])
        cylinder(d = mug_od + clearance, h = rim_depth + 1);

    // Full-width concave bowl — sphere tangent to the outer edge
    translate([0, 0, rim_depth + lid_thick + bowl_r - bowl_depth])
        sphere(r = bowl_r);

    // Pit hole through center
    cylinder(d = pit_hole_d, h = rim_depth + lid_thick + 1);
}
