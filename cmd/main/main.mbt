///|
fn cube_vertex(index : Int) -> (Double, Double, Double) {
  match index {
    0 => (-1.0, -1.0, -1.0)
    1 => (1.0, -1.0, -1.0)
    2 => (1.0, 1.0, -1.0)
    3 => (-1.0, 1.0, -1.0)
    4 => (-1.0, -1.0, 1.0)
    5 => (1.0, -1.0, 1.0)
    6 => (1.0, 1.0, 1.0)
    _ => (-1.0, 1.0, 1.0)
  }
}

///|
fn cube_edge(index : Int) -> (Int, Int) {
  match index {
    0 => (0, 1)
    1 => (1, 2)
    2 => (2, 3)
    3 => (3, 0)
    4 => (4, 5)
    5 => (5, 6)
    6 => (6, 7)
    7 => (7, 4)
    8 => (0, 4)
    9 => (1, 5)
    10 => (2, 6)
    _ => (3, 7)
  }
}

///|
fn rotate_y(
  x : Double,
  y : Double,
  z : Double,
  angle : Double,
) -> (Double, Double, Double) {
  let cos_a = @math.cos(angle)
  let sin_a = @math.sin(angle)
  (x * cos_a + z * sin_a, y, z * cos_a - x * sin_a)
}

///|
fn rotate_x(
  x : Double,
  y : Double,
  z : Double,
  angle : Double,
) -> (Double, Double, Double) {
  let cos_a = @math.cos(angle)
  let sin_a = @math.sin(angle)
  (x, y * cos_a - z * sin_a, y * sin_a + z * cos_a)
}

///|
fn project_point(x : Double, y : Double, z : Double) -> (Int, Int) {
  let depth = z + 4.5
  let scale = 28.0 / depth
  ((x * scale + 44.0).round().to_int(), (y * scale + 24.0).round().to_int())
}

///|
fn edge_style(index : Int, depth : Double) -> @drawille.Style {
  let cool = 140 + (depth * 25.0).to_int()
  let warm = 90 + index * 12
  @drawille.with_fg(
    @drawille.default_style(),
    @drawille.rgb(warm, 220 - index * 8, cool),
  )
}

///|
fn render_cube_frame(angle : Double) -> String {
  let canvas = @drawille.Canvas::new()
  canvas.set_text(0, 0, "Rotating Wireframe Cube")
  canvas.set_text(0, 4, "ANSI redraw demo")
  for edge = 0; edge < 12; edge = edge + 1 {
    let (from_index, to_index) = cube_edge(edge)
    let (ax0, ay0, az0) = cube_vertex(from_index)
    let (bx0, by0, bz0) = cube_vertex(to_index)
    let (ax1, ay1, az1) = rotate_y(ax0, ay0, az0, angle)
    let (bx1, by1, bz1) = rotate_y(bx0, by0, bz0, angle)
    let (ax2, ay2, az2) = rotate_x(ax1, ay1, az1, angle * 0.6)
    let (bx2, by2, bz2) = rotate_x(bx1, by1, bz1, angle * 0.6)
    let (x1, y1) = project_point(ax2 * 18.0, ay2 * 18.0, az2)
    let (x2, y2) = project_point(bx2 * 18.0, by2 * 18.0, bz2)
    let style = edge_style(edge, (az2 + bz2) / 2.0)
    canvas.stroke_line(x1, y1, x2, y2, style~)
  }
  canvas.render()
}

///|
fn pause_frame() -> Unit {
  for spin = 0; spin < 800000; spin = spin + 1 {
    ()
  }
}

///|
fn main {
  println("\u001b[2J\u001b[?25l")
  for frame = 0; frame < 48; frame = frame + 1 {
    let angle = frame.to_double() * 0.18
    println("\u001b[H\{render_cube_frame(angle)}")
    pause_frame()
  }
  println("\u001b[?25h")
}
