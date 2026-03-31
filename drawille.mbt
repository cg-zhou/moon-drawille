///|
/// Basic ANSI color names used by the public color model.
pub enum BasicColor {
  Black
  Red
  Green
  Yellow
  Blue
  Magenta
  Cyan
  White
} derive(Eq, Show)

///|
/// Public color abstraction for terminal styling.
pub enum Color {
  Default
  Ansi(BasicColor, Bool)
  Rgb(Int, Int, Int)
} derive(Eq, Show)

///|
/// Style metadata attached to text or braille content.
pub struct Style {
  fg : Color
  bg : Color
} derive(Eq, Show)

///|
/// Rendering controls for terminal output.
pub struct RenderOptions {
  line_ending : String
  enable_ansi : Bool
  reset_each_line : Bool
} derive(Eq, Show)

///|
/// Logical pixel and text surface.
///
/// Use a Map to store cell content. Each key is (cell_x, cell_y).
/// Each cell contains a bitmask for braille, optional text, and optional style.
pub struct Canvas {
  cells : Map[(Int, Int), Cell]
}

///|
struct Cell {
  mut braille : Int // 8-bit mask
  mut text : String
  mut style : Style
}

///|
test "braille_mapping" {
  let c = Canvas::new()
  c.set(0, 0)
  c.set(1, 0)
  c.set(0, 1)
  c.set(1, 1)
  c.set(0, 2)
  c.set(1, 2)
  c.set(0, 3)
  c.set(1, 3)
  let s = c.render(options={ ..default_render_options(), enable_ansi: false })
  // All dots in a 2x4 cell should be 0x28FF
  assert_eq(s, "\u28FF\n")
}

///|
test "coordinates" {
  let c = Canvas::new()
  c.set(-1, -1) // cx=-1, cy=-1, px=1, py=3 -> bit 7
  let s = c.render(options={ ..default_render_options(), enable_ansi: false })
  assert_eq(s, "\u2880\n")
}

///|
test "text_overlay" {
  let c = Canvas::new()
  c.set(0, 0)
  c.set_text(0, 0, "HI")
  let s = c.render(options={ ..default_render_options(), enable_ansi: false })
  // Text should replace braille in the same cell
  assert_eq(s, "HI\n") // Min X is 0, Max X is 1 (where I is)
}

///|
test "ansi_colors" {
  let c = Canvas::new()
  let red_style = { ..default_style(), fg: Ansi(Red, false) }
  c.set(0, 0)
  c.set_style(0, 0, red_style)
  let s = c.render(options={ ..default_render_options(), enable_ansi: true })
  assert_true(s.contains("\u001b[0;31m"))
  assert_true(s.contains("\u2801"))
  assert_true(s.contains("\u001b[0m"))
}

///|
test "basic_palette_coverage" {
  let c = Canvas::new()
  let colors = [Black, Red, Green, Yellow, Blue, Magenta, Cyan, White]
  for i = 0; i < colors.length(); i = i + 1 {
    let style = with_fg(default_style(), Ansi(colors[i], false))
    c.set(i * 2, 0)
    c.set_style(i * 2, 0, style)
  }
  let s = c.render(options={ ..default_render_options(), enable_ansi: true })
  assert_true(s.contains("\u001b[0;30m"))
  assert_true(s.contains("\u001b[0;37m"))
}

///|
test "line_drawing" {
  let c = Canvas::new()
  c.stroke_line(0, 0, 2, 0) // (0,0), (1,0), (2,0)
  let s = c.render(options={ ..default_render_options(), enable_ansi: false })
  // (0,0) and (1,0) in cell (0,0) -> bit 0, 3 -> 1|8 = 9
  // (2,0) in cell (1,0) -> px=0, py=0 -> bit 0
  assert_eq(s, "\u2809\u2801\n")
}

///|
/// Default style with terminal default foreground/background and all flags off.
pub fn default_style() -> Style {
  { fg: Default, bg: Default }
}

///|
/// Default rendering options for ANSI-capable terminal output.
pub fn default_render_options() -> RenderOptions {
  { line_ending: "\n", enable_ansi: true, reset_each_line: true }
}

///|
/// Return a copy of a style with a different foreground color.
pub fn with_fg(style : Style, fg : Color) -> Style {
  { fg, bg: style.bg }
}

///|
/// Return rendering options with ANSI output disabled.
pub fn without_ansi(options : RenderOptions) -> RenderOptions {
  {
    line_ending: options.line_ending,
    enable_ansi: false,
    reset_each_line: options.reset_each_line,
  }
}

///|
/// Clamp an RGB channel to the inclusive range `[0, 255]`.
pub fn clamp_rgb(channel : Int) -> Int {
  if channel < 0 {
    0
  } else if channel > 255 {
    255
  } else {
    channel
  }
}

///|
/// Construct a truecolor value after clamping each channel.
pub fn rgb(r : Int, g : Int, b : Int) -> Color {
  Rgb(clamp_rgb(r), clamp_rgb(g), clamp_rgb(b))
}

///|
/// Create an empty logical canvas.
pub fn Canvas::new() -> Canvas {
  { cells: Map::new() }
}

///|
/// Clear all canvas content.
pub fn Canvas::clear(self : Canvas) -> Unit {
  self.cells.clear()
}

///|
fn Canvas::get_or_create_cell(self : Canvas, cx : Int, cy : Int) -> Cell {
  match self.cells.get((cx, cy)) {
    Some(cell) => cell
    None => {
      let cell = { braille: 0, text: "", style: default_style() }
      self.cells.set((cx, cy), cell)
      cell
    }
  }
}

// Braille dot mapping within a 2x4 cell:
// (0,0) (1,0)  -> bit 0, 3
// (0,1) (1,1)  -> bit 1, 4
// (0,2) (1,2)  -> bit 2, 5
// (0,3) (1,3)  -> bit 6, 7

///|
fn pixel_to_bit(px : Int, py : Int) -> Int {
  match (px, py) {
    (0, 0) => 0
    (0, 1) => 1
    (0, 2) => 2
    (1, 0) => 3
    (1, 1) => 4
    (1, 2) => 5
    (0, 3) => 6
    (1, 3) => 7
    _ => 0
  }
}

///|
/// Activate one logical pixel.
pub fn Canvas::set(self : Canvas, x : Int, y : Int) -> Unit {
  let cx = x / 2
  let cy = y / 4
  let px = x % 2
  let py = y % 4
  // Handle negatives for modulo
  let (px, cx) = if px < 0 { (px + 2, cx - 1) } else { (px, cx) }
  let (py, cy) = if py < 0 { (py + 4, cy - 1) } else { (py, cy) }

  let cell = self.get_or_create_cell(cx, cy)
  cell.braille = cell.braille | (1 << pixel_to_bit(px, py))
}

///|
/// Deactivate one logical pixel.
pub fn Canvas::unset(self : Canvas, x : Int, y : Int) -> Unit {
  let cx = x / 2
  let cy = y / 4
  let px = x % 2
  let py = y % 4
  let (px, cx) = if px < 0 { (px + 2, cx - 1) } else { (px, cx) }
  let (py, cy) = if py < 0 { (py + 4, cy - 1) } else { (py, cy) }

  match self.cells.get((cx, cy)) {
    Some(cell) =>
      cell.braille = cell.braille & (1 << pixel_to_bit(px, py)).lnot()
    None => ()
  }
}

///|
/// Write text at a logical position with optional style.
pub fn Canvas::set_text(
  self : Canvas,
  x : Int,
  y : Int,
  text : String,
  style? : Style = default_style(),
) -> Unit {
  let cx = x / 2
  let cy = y / 4
  // We place text cell-by-cell. Multi-character text advances horizontally.
  for i, char in text {
    let cell = self.get_or_create_cell(cx + i, cy)
    cell.text = char.to_string()
    cell.style = style
  }
}

///|
/// Apply a style to content located at a logical position.
pub fn Canvas::set_style(
  self : Canvas,
  x : Int,
  y : Int,
  style : Style,
) -> Unit {
  let cx = x / 2
  let cy = y / 4
  let cell = self.get_or_create_cell(cx, cy)
  cell.style = style
}

///|
/// Draw a styled line segment on the canvas.
/// Use Bresenham's algorithm for drawing lines.
pub fn Canvas::stroke_line(
  self : Canvas,
  x1 : Int,
  y1 : Int,
  x2 : Int,
  y2 : Int,
  style? : Style = default_style(),
) -> Unit {
  let dx = (x2 - x1).abs()
  let dy = -(y2 - y1).abs()
  let sx = if x1 < x2 { 1 } else { -1 }
  let sy = if y1 < y2 { 1 } else { -1 }
  let mut err = dx + dy
  let mut cur_x = x1
  let mut cur_y = y1

  while true {
    self.set(cur_x, cur_y)
    self.set_style(cur_x, cur_y, style)
    if cur_x == x2 && cur_y == y2 {
      break
    }
    let e2 = 2 * err
    if e2 >= dy {
      err += dy
      cur_x += sx
    }
    if e2 <= dx {
      err += dx
      cur_y += sy
    }
  }
}

///|
/// Render the current canvas into a terminal string.
pub fn Canvas::render(
  self : Canvas,
  options? : RenderOptions = default_render_options(),
) -> String {
  let mut min_x = 0
  let mut max_x = 0
  let mut min_y = 0
  let mut max_y = 0
  let mut first = true

  self.cells.each(fn(k, _) {
    let (cx, cy) = k
    if first {
      min_x = cx
      max_x = cx
      min_y = cy
      max_y = cy
      first = false
    } else {
      if cx < min_x {
        min_x = cx
      }
      if cx > max_x {
        max_x = cx
      }
      if cy < min_y {
        min_y = cy
      }
      if cy > max_y {
        max_y = cy
      }
    }
  })

  let sb = StringBuilder::new()
  let mut current_style = default_style()

  for cy = min_y; cy <= max_y; cy = cy + 1 {
    for cx = min_x; cx <= max_x; cx = cx + 1 {
      match self.cells.get((cx, cy)) {
        Some(cell) => {
          if options.enable_ansi {
            let ansi = get_ansi_sequence(cell.style, current_style)
            sb.write_string(ansi)
            current_style = cell.style
          }
          if cell.text != "" {
            sb.write_string(cell.text)
          } else if cell.braille != 0 {
            let char_code = 0x2800 + cell.braille
            sb.write_char(char_code.unsafe_to_char())
          } else {
            sb.write_string(" ")
          }
        }
        None => {
          if options.enable_ansi && current_style != default_style() {
            sb.write_string("\u001b[0m")
            current_style = default_style()
          }
          sb.write_string(" ")
        }
      }
    }
    if options.enable_ansi && options.reset_each_line {
      sb.write_string("\u001b[0m")
      current_style = default_style()
    }
    sb.write_string(options.line_ending)
  }

  if options.enable_ansi && current_style != default_style() {
    sb.write_string("\u001b[0m")
  }

  sb.to_string()
}

///|
fn get_ansi_sequence(style : Style, prev : Style) -> String {
  if style == prev {
    return ""
  }
  if style == default_style() {
    return "\u001b[0m"
  }

  let sb = StringBuilder::new()
  sb.write_string("\u001b[0") // Reset or start fresh

  match style.fg {
    Default => ()
    Ansi(color, bright) => {
      let code = match color {
        Black => 30
        Red => 31
        Green => 32
        Yellow => 33
        Blue => 34
        Magenta => 35
        Cyan => 36
        White => 37
      }
      let final_code = if bright { code + 60 } else { code }
      sb.write_string(";\{final_code}")
    }
    Rgb(r, g, b) => sb.write_string(";38;2;\{r};\{g};\{b}")
  }

  match style.bg {
    Default => ()
    Ansi(color, bright) => {
      let code = match color {
        Black => 40
        Red => 41
        Green => 42
        Yellow => 43
        Blue => 44
        Magenta => 45
        Cyan => 46
        White => 47
      }
      let final_code = if bright { code + 60 } else { code }
      sb.write_string(";\{final_code}")
    }
    Rgb(r, g, b) => sb.write_string(";48;2;\{r};\{g};\{b}")
  }

  sb.write_string("m")
  sb.to_string()
}
