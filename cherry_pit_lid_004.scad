// Cherry Pit Lid v004 - concave top and bottom
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

// Top bowl: spans full lid width, dips lid_thick-2mm
top_depth  = lid_thick - 2;
top_bowl_r = (outer_r * outer_r + top_depth * top_depth) / (2 * top_depth);

bot_recess_d = outer_d - wall * 2;  // recess inset from outer edge
bot_recess_h = 3;                    // depth of bottom recess

difference() {
    cylinder(d = outer_d, h = rim_depth + lid_thick);

    // Collar bore (fits over mug rim)
    translate([0, 0, lid_thick])
        cylinder(d = mug_od + clearance, h = rim_depth + 1);

    // Top concave bowl
    translate([0, 0, rim_depth + lid_thick + top_bowl_r - top_depth])
        sphere(r = top_bowl_r);

    // Bottom concave recess — leaves a rim ring on the underside
    translate([0, 0, -0.1])
        cylinder(d = bot_recess_d, h = bot_recess_h + 0.1);

    // Pit hole through center
    cylinder(d = pit_hole_d, h = rim_depth + lid_thick + 1);
}
