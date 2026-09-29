-- Выбор квартиры: хрущёвка в разрезе. Решённые квартиры горят, вода в стояке поднимается до верхней
-- решённой; открыты две нерешённые сразу; остальные заколочены.
local UI = require("game.ui")
local Board = require("game.board")
local Levels = require("game.levels")
local lg = love.graphics
local Select = {}
Select.__index = Select

local function aptRect(n)
  local fl = math.floor((n + 1) / 2)
  return (n % 2 == 1) and 580 or 990, 940 - fl * 150 + 10, 350, 130
end

function Select.new(app, focus)
  local self = setmetatable({ app = app, t = 0, bg = Board.img("scr_building"), sol = Levels.solutions() }, Select)
  self.state = app.availability()
  self.sel = focus
  if not self.sel or self.state[self.sel] == "locked" then
    self.sel = 1
    for i = 1, #app.levels do if self.state[i] == "open" then self.sel = i; break end end
  end
  return self
end

function Select:update(dt) self.t = self.t + dt end

function Select:draw()
  local F, App = self.app.font, self.app
  lg.setColor(1, 1, 1)
  if self.bg then lg.draw(self.bg, 0, 0) end
  local top = 0
  for i = 1, #App.levels do if self.state[i] == "solved" then top = math.max(top, math.floor((i + 1) / 2)) end end
  if top > 0 then lg.setColor(0.18, 0.77, 0.945); lg.rectangle("fill", 954, 940 - top * 150, 12, top * 150) end
  for i = 1, #App.levels do
    local x, y = aptRect(i)
    local s = self.state[i]
    local im = s ~= "locked" and Board.img(string.format("apt%d_%s", i, s)) or nil
    lg.setColor(1, 1, 1)
    if im then lg.draw(im, x - 8, y - 8) end
  end
  local x, y, w, h = aptRect(self.sel)
  local p = 0.5 + 0.5 * math.sin(self.t * 5)
  lg.setColor(0.965, 0.859, 0.541, 0.6 + 0.4 * p); lg.setLineWidth(6 + 3 * p)
  lg.rectangle("line", x - 10, y - 10, w + 20, h + 20, 12)
  local def = App.levels[self.sel]
  local st = self.state[self.sel]
  local line = "открыта — можно брать"
  if st == "solved" then
    local best = App.save.best[tostring(self.sel)]
    local s = self.sol[string.format("%02d", self.sel)]
    local g = UI.grade(best, s and s.moves and #s.moves or nil)
    line = string.format("акт подписан: %s ходов%s", tostring(best or "—"), g and (", " .. g .. "-й разряд") or "")
  end
  -- строки идут друг под другом по фактической высоте переноса, табличка растёт под текст
  local name = "«" .. def.name .. "»"
  local lines = { line, UI.isMobile() and "касание — войти" or "Enter — войти, Esc — в подвал" }
  local function hgt(font, t) return #select(2, font:getWrap(t, 390)) * font:getHeight() end
  local total = 76 + hgt(F.hand, name) + 14
  for _, t in ipairs(lines) do total = total + hgt(F.xs, t) + 8 end
  UI.plate(40, 320, 440, math.max(250, total + 30))
  lg.setFont(F.b); UI.setc(UI.GOLD); lg.print(string.format("Квартира %d", self.sel), 70, 346)
  lg.setFont(F.hand); UI.setc(UI.CREAM); lg.printf(name, 70, 396, 390)
  lg.setFont(F.xs); lg.setColor(0.79, 0.83, 0.86)
  local ty = 396 + hgt(F.hand, name) + 14
  for _, t in ipairs(lines) do
    lg.printf(t, 70, ty, 390)
    ty = ty + hgt(F.xs, t) + 8
  end
end

function Select:enter(i)
  if self.state[i] and self.state[i] ~= "locked" then self.app.play(i) end
end

function Select:move(dx, dy)
  local n = #self.app.levels
  local cand = self.sel + dx + dy * 2
  if cand >= 1 and cand <= n and self.state[cand] ~= "locked" then self.sel = cand end
end

function Select:key(k)
  if k == "left" or k == "a" then self:move(-1, 0) elseif k == "right" or k == "d" then self:move(1, 0)
  elseif k == "up" or k == "w" then self:move(0, 1) elseif k == "down" or k == "s" then self:move(0, -1)
  elseif k == "return" or k == "kpenter" or k == "space" then self:enter(self.sel)
  elseif k == "escape" then self.app.go("menu") end
end

function Select:pad(b)
  local m = { dpleft = "left", dpright = "right", dpup = "up", dpdown = "down", a = "return", b = "escape", start = "escape" }
  if m[b] then self:key(m[b]) end
end

function Select:pointer(kind, x, y)
  if kind ~= "release" then return end
  for i = 1, #self.app.levels do
    local ax, ay, w, h = aptRect(i)
    if UI.inside(x, y, { ax, ay, w, h }) then
      if self.sel == i then return self:enter(i) end
      if self.state[i] ~= "locked" then self.sel = i end
      return
    end
  end
end
return Select
