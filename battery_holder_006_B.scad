// Type B holder plates (bottom face, hex option), sectioned 2x2 for printing.
// Individual pieces: render battery_holder_006.scad with
//   -D 'mode="piece"' -D 'pattern="B"' -D piece_c=<0-1> -D piece_r=<0-1>
use <battery_holder_006.scad>
holder_sectioned("B");
