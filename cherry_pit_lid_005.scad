// Cherry Pit Lid v005 - sphere-carved base (thick edges, thin center)
// Sits on standard coffee mug ~85mm outer rim diameter

$fn = 80;

mug_od      = 85;
clearance   = 0.6;
wall        = 3.5;
rim_depth   = 5;
lid_thick   = 8;
pit_hole_d  = 18;

outer_d = mug_od + wall * 2;
outer_r = outer_d / 2;

// Top bowl: spans full lid width, dips lid_thick-2mm
top_depth  = lid_thick - 2;
top_bowl_r = (outer_r * outer_r + top_depth * top_depth) / (2 * top_depth);

// Bottom dome: sphere carved upward through the base center
// bot_center_dip = how far up from the bottom the center is carved (leaves lid_thick-bot_center_dip at center)
bot_center_dip = 5;   // 5mm dip → 3mm thick at center, 8mm thick at edges
bot_sphere_r   = 100; // large radius = gentle dome curve

difference() {
    cylinder(d = outer_d, h = rim_depth + lid_thick);

    // Collar bore (fits over mug rim)
    translate([0, 0, lid_thick])
        cylinder(d = mug_od + clearance, h = rim_depth + 1);

    // Top concave bowl
    translate([0, 0, rim_depth + lid_thick + top_bowl_r - top_depth])
        sphere(r = top_bowl_r);

    // Bottom dome — sphere center below the base, carves upward through center only
    translate([0, 0, -(bot_sphere_r - bot_center_dip)])
        sphere(r = bot_sphere_r);

    // Pit hole through center
    cylinder(d = pit_hole_d, h = rim_depth + lid_thick + 1);
}
