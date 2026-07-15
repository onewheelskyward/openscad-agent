// Type A holder plates (top face, hex option), sectioned 3x3 for printing.
// Individual pieces: render battery_holder_006.scad with
//   -D 'mode="piece"' -D 'pattern="A"' -D piece_c=<0-2> -D piece_r=<0-2>
use <battery_holder_006.scad>
holder_sectioned("A");
