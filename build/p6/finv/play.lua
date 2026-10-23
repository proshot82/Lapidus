-- build/p6/finv/play.lua — «пульт» для слепого игрока: применяет ходы к уровню и печатает поле текстом.
-- Солвера нет, решение не печатается. luajit build/p6/finv/play.lua "head:left heel:up …" [all]
-- Ходы: head|heel : up|down|left|right. С аргументом all — поле после каждого хода, иначе только старт и итог.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local def = dofile("build/p6/fin/final.lua")
local lvl = R.compile(def)
local st = R.newState(lvl)
local NAME = { cpl = "m", nip = "n" }
local function show(s, label)
  print(label)
  local rows = {}
  for y = 1, lvl.H do rows[y] = {} for x = 1, lvl.W do local c = lvl.cell[(y-1)*lvl.W+x]; rows[y][x] = c == 1 and "#" or (c == 2 and "~" or ".") end end
  for q, pp in ipairs(lvl.pieces) do
    if s.pos[q] ~= 0 then
      local x, y = R.xy(lvl, s.pos[q])
      local ch = ({ source = "S", fixture = "K" })[pp.kind] or NAME[pp.tag] or "?"
      if pp.movable and s.fixed[q] then ch = ch:upper() end
      rows[y][x] = ch
    end
  end
  if not s.dead then for i, c in ipairs(s.body) do local x, y = R.xy(lvl, c); rows[y][x] = (i == #s.body) and "H" or ((i == 1) and "f" or "o") end end
  for y = 1, lvl.H do print("  " .. table.concat(rows[y])) end
  local w = R.status(lvl, s)
  local lost = {}
  for q, pp in ipairs(lvl.pieces) do if pp.movable and s.pos[q] == 0 then lost[#lost + 1] = NAME[pp.tag] .. " смыта в слив" end end
  print(string.format("  %s%s%s", s.dead and "ЛАПИДУС СМЫТ. " or "", w.win and "ПОБЕДА. " or "", table.concat(lost, ", ")))
  if def.visibleLoss and not s.dead and not w.win and def.visibleLoss(lvl, s) then print("  все детали закреплены, а победы нет — тупик") end
end
show(st, "старт")
local all = arg[2] == "all"
local n = 0
for tok in (arg[1] or ""):gmatch("%S+") do
  local m = R.parseMove(tok)
  local mm = R.MOVES[m]
  local ns = R.move(lvl, st, mm.which, mm.dir)
  n = n + 1
  if not ns then print(string.format("ход %d %s — невозможен, пропущен", n, tok))
  else st = ns; if all then show(st, string.format("после хода %d (%s)", n, tok)) end end
end
if not all and n > 0 then show(st, string.format("после %d ходов", n)) end
