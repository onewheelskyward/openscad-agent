// fender_washer_001.scad
// Fender washer: 10.5mm bore, 25mm OD, 3mm thick.

$fn = 128;

id = 10.5;
od = 25;
t  = 3;

difference() {
    cylinder(d=od, h=t);
    translate([0, 0, -1]) cylinder(d=id, h=t + 2);
}
