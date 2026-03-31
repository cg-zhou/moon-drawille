///|
fn render_mandelbrot(zoom : Double) -> String {
  let canvas = @drawille.Canvas::new()
  let width = 160.0
  let height = 80.0
  
  let center_x = -0.743643887037158
  let center_y = 0.131825904205312
  
  canvas.set_text(4, 4, " Mandelbrot Zoom: \{zoom} ")

  for py = 0; py < height.to_int(); py = py + 1 {
    for px = 0; px < width.to_int(); px = px + 1 {
      let x0 = center_x + (px.to_double() / width - 0.5) * 3.5 / zoom
      let y0 = center_y + (py.to_double() / height - 0.5) * 2.0 / zoom
      
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
        let intensity = iteration.to_double()
        let r = (@math.sin(0.3 * intensity + 0.0) * 127.0 + 128.0).to_int()
        let g = (@math.sin(0.3 * intensity + 2.0) * 127.0 + 128.0).to_int()
        let b = (@math.sin(0.3 * intensity + 4.0) * 127.0 + 128.0).to_int()
        
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
  let mut zoom = 1.0
  for i = 0; i < 40; i = i + 1 {
    // 使用 ANSI 逃逸序列清屏并移动光标到左上角
    // 使用 \u001b 替代 \x1b
    println("\u001b[2J\u001b[H")
    
    println(render_mandelbrot(zoom))
    
    // 增加延时
    let start = @env.now()
    while @env.now() - start < 100 {
    }
    
    zoom = zoom * 1.2
  }
}
