attribute vec2 coord2d;

void main() {
  vec2 c = vec2(coord2d.x  - 1, coord2d.y - 3.0);
  gl_Position = vec4(c, 1.0, 1.0);
}