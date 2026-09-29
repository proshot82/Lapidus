-- Сцены, виртуальное разрешение 1920×1080 с полями, шрифты, сохранения.
local App = { W = 1920, H = 1080, scale = 1, ox = 0, oy = 0, frame = 0 }

local function argValue(args, name)
  for i, a in ipairs(args or {}) do if a == name then return args[i + 1] or true end end
end

function App.load(args)
  App.args = args or {}
  local UI, UIB, HAND = "assets/fonts/PT_Sans-Narrow-Web-Regular.ttf", "assets/fonts/PT_Sans-Narrow-Web-Bold.ttf", "assets/fonts/Neucha-Regular.ttf"
  local nf = love.graphics.newFont
  App.font = { xs = nf(UI, 28), s = nf(UIB, 26), m = nf(UI, 36), b = nf(UIB, 38), l = nf(UIB, 66), num = nf(UIB, 80), digit = nf(UIB, 60),
               hand = nf(HAND, 42), handL = nf(HAND, 60), gradeF = nf(HAND, 84), menu = nf(UIB, 46) }
  App.save = require("game.save").load()
  App.levels = require("game.levels").load()
  App.resize(love.graphics.getDimensions())
  App.shot = argValue(App.args, "--shot")
  App.autoplay = argValue(App.args, "--autoplay") and true or false
  App.demo = argValue(App.args, "--demo")
  App.unlockAll = argValue(App.args, "--unlock") and true or false -- пробная сборка для автора: все квартиры открыты
  local lv = tonumber(argValue(App.args, "--level") or "")
  local screen = argValue(App.args, "--screen")
  if lv or App.autoplay then
    App.go("play", math.min(lv or 1, #App.levels))
  elseif screen == "select" or screen == "passport" then
    App.go(screen)
  else
    App.go("menu")
  end
end

function App.go(name, arg)
  if name == "menu" then App.scene = require("game.menu").new(App)
  elseif name == "select" then App.scene = require("game.select").new(App, arg)
  elseif name == "passport" then App.scene = require("game.passport").new(App, arg)
  else App.scene = require("game.play").new(App, arg) end
end

function App.play(index)
  if not App.save.passportSeen then App.go("passport", { play = index }) else App.go("play", index) end
end

function App.availability()
  local st, open = {}, 0
  for i = 1, #App.levels do
    if App.save.solved[tostring(i)] then st[i] = "solved"
    elseif App.unlockAll or open < 2 then st[i] = "open"; open = open + 1
    else st[i] = "locked" end
  end
  return st
end

function App.continueIndex()
  local st = App.availability()
  local cur = App.save.current
  if cur and st[cur] and st[cur] ~= "solved" then return cur end
  for i = 1, #App.levels do if st[i] == "open" then return i end end
  return 1
end

function App.resize(w, h)
  App.scale = math.min(w / App.W, h / App.H)
  App.ox = (w - App.W * App.scale) / 2
  App.oy = (h - App.H * App.scale) / 2
end

function App.toVirtual(x, y) return (x - App.ox) / App.scale, (y - App.oy) / App.scale end

function App.update(dt)
  App.frame = App.frame + 1
  if App.scene and App.scene.update then App.scene:update(math.min(dt, 0.05)) end
  if App.shot and App.frame == (tonumber(App.shotFrame) or 8) then
    local path = App.shot
    love.graphics.captureScreenshot(function(img)
      local fh = io.open(path, "wb")
      if fh then fh:write(img:encode("png"):getString()); fh:close() end
      if not App.autoplay then love.event.quit() end
    end)
  end
end

function App.draw()
  love.graphics.clear(0.07, 0.07, 0.08)
  love.graphics.push()
  love.graphics.translate(App.ox, App.oy)
  love.graphics.scale(App.scale)
  if App.scene and App.scene.draw then App.scene:draw() end
  love.graphics.pop()
end

function App.key(k) App.lastInput = "key"; if App.scene and App.scene.key then App.scene:key(k) end end
function App.pad(b) App.lastInput = "pad"; if App.scene and App.scene.pad then App.scene:pad(b) end end
function App.pointer(kind, x, y)
  App.lastInput = "touch"
  local vx, vy = App.toVirtual(x, y)
  if App.scene and App.scene.pointer then App.scene:pointer(kind, vx, vy) end
end

return App
