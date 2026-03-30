///|
fn render_mandelbrot() -> String {
  let canvas = @drawille.Canvas::new()
  let width = 160.0
  let height = 80.0
  
  canvas.set_text(4, 4, " Mandelbrot Set ")

  for py = 0; py < height.to_int(); py = py + 1 {
    for px = 0; px < width.to_int(); px = px + 1 {
      let x0 = px.to_double() / width * 3.5 - 2.5
      let y0 = py.to_double() / height * 2.0 - 1.0
      
      let mut x = 0.0
      let mut y = 0.0
      let mut iteration = 0
      let max_iteration = 100
      
      while x * x + y * y <= 4.0 && iteration < max_iteration {
        let xtemp = x * x - y * y + x0
        y = 2.0 * x * y + y0
        x = xtemp
        iteration = iteration + 1
      }
      
      if iteration < max_iteration {
        // 或者使用更直接的周期性颜色
        let intensity = iteration.to_double()
        let r = ( @math.sin(0.3 * intensity + 0.0) * 127.0 + 128.0).to_int()
        let g = ( @math.sin(0.3 * intensity + 2.0) * 127.0 + 128.0).to_int()
        let b = ( @math.sin(0.3 * intensity + 4.0) * 127.0 + 128.0).to_int()
        
        let style = @drawille.with_fg(@drawille.default_style(), @drawille.rgb(r, g, b))
        canvas.set(px, py)
        canvas.set_style(px, py, style)
      }
    }
  }
  canvas.render()
}

///|
fn main {
  println(render_mandelbrot())
}
