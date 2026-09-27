-- «Паспорт изделия»: правила в пиктограммах. Показывается перед первой квартирой и из меню.
local Board = require("game.board")
local SaveM = require("game.save")
local UI = require("game.ui")
local lg = love.graphics
local Passport = {}
Passport.__index = Passport

function Passport.new(app, after)
  return setmetatable({ app = app, after = after or { back = "menu" }, bg = Board.img("scr_passport") }, Passport)
end
function Passport:update(dt) end
function Passport:draw()
  lg.setColor(1, 1, 1)
  if self.bg then lg.draw(self.bg, 0, 0) end
  lg.setFont(self.app.font.xs); UI.setc(UI.CREAM)
  lg.printf("любая клавиша или касание — дальше", 0, 1044, 1920, "center")
end
function Passport:done()
  local App = self.app
  App.save.passportSeen = true
  SaveM.write(App.save)
  if self.after.play then App.go("play", self.after.play) else App.go("menu") end
end
function Passport:key() self:done() end
function Passport:pad() self:done() end
function Passport:pointer(kind) if kind == "release" then self:done() end end
return Passport
