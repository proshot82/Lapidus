-- Меню: подвал у главного вентиля дома (фон — готовая картинка, таблички и надписи рисует движок).
local UI = require("game.ui")
local Board = require("game.board")
local lg = love.graphics
local Menu = {}
Menu.__index = Menu

function Menu.new(app)
  local self = setmetatable({ app = app, sel = 1, t = 0, bg = Board.img("scr_menu") }, Menu)
  self.items = { { id = "continue", label = "Продолжить" }, { id = "select", label = "Квартиры" }, { id = "passport", label = "Паспорт изделия" },
                 { id = "sound", label = app.audio.on and "Звук: вкл" or "Звук: выкл" } }
  if not UI.isMobile() then self.items[#self.items + 1] = { id = "quit", label = "Выход" } end
  return self
end

function Menu:update(dt) self.t = self.t + dt end

function Menu:draw()
  local F = self.app.font
  lg.setColor(1, 1, 1)
  if self.bg then lg.draw(self.bg, 0, 0) end
  if #self.app.levels < 10 then
    lg.setFont(F.xs); UI.setc(UI.GOLD, 0.8)
    lg.printf(string.format("тестовая сборка: %d квартир из 10", #self.app.levels), 0, 1030, 1880, "right")
  end
  for i, it in ipairs(self.items) do
    local x, y, w, h = 1180, 586 + (i - 1) * 86, 540, 72
    it.rect = { x, y, w, h }
    if i == self.sel then UI.brass(x, y, w, h) else UI.plate(x, y, w, h) end
    lg.setFont(F.menu)
    if i == self.sel then lg.setColor(0.169, 0.129, 0.094) else UI.setc(UI.CREAM) end
    lg.printf(it.label, x, y + h / 2 - F.menu:getHeight() / 2, w, "center")
  end
end

function Menu:activate(id)
  local App = self.app
  if id == "continue" then App.play(App.continueIndex())
  elseif id == "select" then App.go("select")
  elseif id == "passport" then App.go("passport", { back = "menu" })
  elseif id == "sound" then
    local on = App.audio.toggle()
    App.save.settings = App.save.settings or {}
    App.save.settings.sound = on
    require("game.save").write(App.save)
    for _, it in ipairs(self.items) do if it.id == "sound" then it.label = on and "Звук: вкл" or "Звук: выкл" end end
    App.audio.play("click", 0.7)
  elseif id == "quit" then love.event.quit() end
end

function Menu:key(k)
  if k == "up" or k == "w" then self.sel = (self.sel - 2) % #self.items + 1
  elseif k == "down" or k == "s" then self.sel = self.sel % #self.items + 1
  elseif k == "return" or k == "kpenter" or k == "space" then self:activate(self.items[self.sel].id)
  elseif k == "escape" and not UI.isMobile() then love.event.quit() end
end

function Menu:pad(b)
  if b == "dpup" then self:key("up") elseif b == "dpdown" then self:key("down") elseif b == "a" or b == "start" then self:key("return") end
end

function Menu:pointer(kind, x, y)
  if kind ~= "release" then return end
  for i, it in ipairs(self.items) do
    if UI.inside(x, y, it.rect) then self.sel = i; return self:activate(it.id) end
  end
end
return Menu
