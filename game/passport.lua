-- «Паспорт изделия»: справочник из меню (§5). Страницы — те же вкладыши, что показываются на экране заявки
-- квартиры, где правило вводится; страница открывается, когда открыта её квартира. Перед игрой не показывается.
local Board = require("game.board")
local UI = require("game.ui")
local lg = love.graphics
local Passport = {}
Passport.__index = Passport

-- { вкладыш, квартира, открывается только после решения квартиры }
local PAGES = {
  { "card01", 1 }, { "card01b", 1, true }, { "card01c", 1, true }, { "card03", 3 },
  { "card05", 4 }, { "card04", 7 }, { "card10", 8 },
}

function Passport.new(app, after)
  local self = setmetatable({ app = app, after = after or { back = "menu" } }, Passport)
  local st = app.availability()
  self.pages = {}
  for _, p in ipairs(PAGES) do
    if p[2] <= #app.levels then
      local s = st[p[2]]
      local open = s == "solved" or (s == "open" and not p[3])
      self.pages[#self.pages + 1] = { img = open and Board.img(p[1]) or nil, flat = p[2] }
    end
  end
  return self
end

function Passport:update(dt) end

function Passport:draw()
  local F = self.app.font
  lg.setColor(0.165, 0.188, 0.208); lg.rectangle("fill", 0, 0, 1920, 1080)
  lg.setColor(0.945, 0.925, 0.875); lg.rectangle("fill", 60, 30, 1800, 1000, 10)
  UI.setc(UI.INK); lg.setFont(F.l); lg.print("ПАСПОРТ ИЗДЕЛИЯ", 110, 60)
  lg.setFont(F.m)
  lg.printf("Гофра самоходная «Лапидус». Длина 2–6 клеток. Совместимость с ночным горшком: только ногами. Гарантия на героя не распространяется.", 110, 146, 1700)
  -- до 10 страниц: пять в ряд, два ряда (масштаб под ширину)
  local cols = 5
  local z = math.min(0.78, (1800 - 60 - (cols - 1) * 16) / cols / 564)
  local cw, ch = 564 * z, 380 * z
  local gx = (1920 - cols * cw - (cols - 1) * 16) / 2
  for i, p in ipairs(self.pages) do
    local x = gx + ((i - 1) % cols) * (cw + 16)
    local y = 222 + math.floor((i - 1) / cols) * (ch + 56)
    if p.img then
      local zz = math.min(z, ch / p.img:getHeight()) -- высокий вкладыш кв. 7 — в тот же ряд
      lg.setColor(1, 1, 1); lg.draw(p.img, x, y, 0, zz, zz)
    else
      lg.setColor(0.86, 0.84, 0.79); lg.rectangle("fill", x + 8, y + 8, cw - 22, ch - 22, 8)
      lg.setColor(0.7, 0.68, 0.63); lg.setLineWidth(2); lg.rectangle("line", x + 8, y + 8, cw - 22, ch - 22, 8)
      lg.setFont(F.m); lg.setColor(0.45, 0.44, 0.42)
      lg.printf("откроется в кв. " .. p.flat, x, y + ch / 2 - 24, cw - 8, "center")
    end
  end
  lg.setFont(F.xs); UI.setc(UI.INK)
  lg.printf(UI.isMobile() and "касание — назад" or "любая клавиша — назад", 0, 980, 1920, "center")
end

function Passport:done()
  local App = self.app
  if self.after.play then App.go("play", self.after.play) else App.go("menu") end
end
function Passport:key() self:done() end
function Passport:pad() self:done() end
function Passport:pointer(kind) if kind == "release" then self:done() end end
return Passport
