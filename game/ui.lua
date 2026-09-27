-- Общие элементы интерфейса в утверждённом стиле: латунные и тёмные таблички, цвета, оценка разряда.
local lg = love.graphics
local UI = {}
UI.CREAM, UI.INK, UI.BLUE, UI.GOLD = { 0.957, 0.933, 0.863 }, { 0.137, 0.188, 0.306 }, { 0.11, 0.235, 0.604 }, { 0.965, 0.859, 0.541 }
function UI.setc(c, a) lg.setColor(c[1], c[2], c[3], a or 1) end

function UI.plate(x, y, w, h)
  lg.setColor(0, 0, 0, 0.35); lg.rectangle("fill", x + 5, y + 8, w, h, 16)
  lg.setColor(0.165, 0.149, 0.133); lg.rectangle("fill", x, y, w, h, 16)
  lg.setColor(0.557, 0.408, 0.098); lg.setLineWidth(4); lg.rectangle("line", x, y, w, h, 16)
  lg.setColor(0.788, 0.604, 0.18, 0.5); lg.setLineWidth(1.5); lg.rectangle("line", x + 7, y + 7, w - 14, h - 14, 11)
  lg.setColor(0.557, 0.541, 0.502)
  for _, p in ipairs({ { x + 16, y + 16 }, { x + w - 16, y + 16 }, { x + 16, y + h - 16 }, { x + w - 16, y + h - 16 } }) do lg.circle("fill", p[1], p[2], 5) end
end

function UI.brass(x, y, w, h)
  lg.setColor(0, 0, 0, 0.35); lg.rectangle("fill", x + 5, y + 8, w, h, 14)
  lg.setColor(0.82, 0.635, 0.22); lg.rectangle("fill", x, y, w, h, 14)
  lg.setColor(0.97, 0.886, 0.604, 0.9); lg.rectangle("fill", x + 8, y + 6, w - 16, h * 0.28, 8)
  lg.setColor(0.55, 0.4, 0.1, 0.5); lg.rectangle("fill", x + 8, y + h * 0.72, w - 16, h * 0.2, 8)
  lg.setColor(0.169, 0.129, 0.094); lg.setLineWidth(4); lg.rectangle("line", x, y, w, h, 14)
end

function UI.inside(x, y, r) return r and x >= r[1] and y >= r[2] and x <= r[1] + r[3] and y <= r[2] + r[4] end
function UI.isMobile() local os = love.system.getOS(); return os == "iOS" or os == "Android" or os == "Web" end

-- Разряд по норме (§5): 6-й — ровно по норме, 5-й — до +10 %, 4-й — до +25 %, 3-й — до +50 %, иначе 2-й.
function UI.grade(moves, opt)
  if not opt or not moves then return nil end
  local over = (moves - opt) / opt
  if over <= 0 then return 6 elseif over <= 0.10 then return 5 elseif over <= 0.25 then return 4 elseif over <= 0.50 then return 3 end
  return 2
end
return UI
