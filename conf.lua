function love.conf(t)
  t.identity = "lapidus_ni_kapli"
  t.version = "11.5"
  t.window.title = "Лапидус. Ни капли"
  t.window.width, t.window.height = 1280, 720
  t.window.resizable = true
  t.window.minwidth, t.window.minheight = 640, 360
  t.window.vsync = 1
  t.window.highdpi = true
  t.window.msaa = 4
  t.modules.physics = false
  t.modules.video = false
end
