///|
fn render_mandelbrot(zoom : Double, steps : Int) -> String {
  let canvas = @drawille.Canvas::new()
  let width = 160.0
  let height = 80.0

  // 选一个更有趣的、位于分形边缘的坐标点
  let center_x = -0.7436
  let center_y = 0.1318

  let zoom_str = ((zoom * 100.0).round().to_int().to_double() / 100.0).to_string()
  canvas.set_text(4, 4, " Mandelbrot Zoom: \{zoom_str} ")

  for py = 0; py < height.to_int(); py = py + 1 {
    for px = 0; px < width.to_int(); px = px + 1 {
      let x0 = center_x + (px.to_double() / width - 0.5) * 3.5 / zoom
      let y0 = center_y + (py.to_double() / height - 0.5) * 2.0 / zoom

      let mut iteration = 0
      // 随着缩放增加迭代次数以保持细节
      let max_iteration = 100 + steps * 2

      let mut x_sq = 0.0
      let mut y_sq = 0.0
      let mut x_val = 0.0
      let mut y_val = 0.0

      while x_sq + y_sq <= 4.0 && iteration < max_iteration {
        y_val = 2.0 * x_val * y_val + y0
        x_val = x_sq - y_sq + x0
        x_sq = x_val * x_val
        y_sq = y_val * y_val
        iteration = iteration + 1
      }

      if iteration < max_iteration {
        let intensity = iteration.to_double()
        // 动态调整颜色频率，使颜色随着缩放更加平滑
        let r = (@math.sin(0.1 * intensity + 0.0) * 127.0 + 128.0).to_int()
        let g = (@math.sin(0.1 * intensity + 2.0) * 127.0 + 128.0).to_int()
        let b = (@math.sin(0.1 * intensity + 4.0) * 127.0 + 128.0).to_int()

        let style = @drawille.with_fg(
          @drawille.default_style(),
          @drawille.rgb(r, g, b),
        )
        canvas.set(px, py)
        canvas.set_style(px, py, style)
      }
    }
  }
  canvas.render()
}

///|
fn main {
  let mut zoom = 1.0
  for i = 0; i < 90; i = i + 1 {
    // 使用 ANSI 逃逸序列清屏并移动光标到左上角
    println("\u001b[2J\u001b[H")

    println(render_mandelbrot(zoom, i))

    // 增加延时
    let start = @env.now()
    while @env.now() - start < 80 {

    }
    
    // 稍微放慢缩放速度，延长视觉享受时间
    zoom = zoom * 1.12
  }
}
