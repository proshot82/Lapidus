-- build/l5c/play.lua файл.lua "Hu fr ..." — проиграть ходы и показать кадры (ТОЛЬКО для себя, в выводе инструмента;
-- в файлы, коммиты и отчёты кадры не переносить). H — голова, f — ноги; u/r/d/l — направление. Без ходов — старт.
-- Обозначения: t/T — тройник (своб./закреплён), p/P — заглушка, S — стояк, D — полотенцесушитель, H/o/f — Лапидус.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local def = dofile(arg[1])
local lvl = R.compile(def)
local st = R.newState(lvl)
local function show(s, label)
  local rows = {}
  for y = 1, lvl.H do rows[y] = {} for x = 1, lvl.W do local c = lvl.cell[(y - 1) * lvl.W + x]; rows[y][x] = c == 1 and "#" or (c == 2 and "~" or ".") end end
  for q, p in ipairs(lvl.pieces) do if s.pos[q] ~= 0 then
    local x, y = R.xy(lvl, s.pos[q]); local ch = "?"
    if p.source then ch = "S" elseif p.fixture then ch = "D"
    elseif p.what == "tee" then ch = s.fixed[q] and "T" or "t"
    elseif p.what == "plug" then ch = s.fixed[q] and "P" or "p"
    else ch = s.fixed[q] and "X" or "x" end
    rows[y][x] = ch end end
  if not s.dead then for i, c in ipairs(s.body) do local x, y = R.xy(lvl, c); rows[y][x] = (i == #s.body) and "H" or ((i == 1) and "f" or "o") end end
  print(label .. (s.dead and " DEAD" or "") .. (R.isWin(lvl, s) and " WIN" or ""))
  for y = 1, lvl.H do print("  " .. table.concat(rows[y])) end
end
show(st, "start")
local D = { u = 1, r = 2, d = 3, l = 4 }
for tok in (arg[2] or ""):gmatch("%S+") do
  local w = tok:sub(1, 1) == "H" and "head" or "heel"
  local ns, why = R.move(lvl, st, w, D[tok:sub(2, 2)])
  if not ns then print(tok .. ": нельзя (" .. tostring(why) .. ")") else st = ns; show(st, tok) end
end
