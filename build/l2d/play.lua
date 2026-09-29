-- build/l2d/play.lua файл ход1 ход2 ... — проиграть ходы (f/H + u/r/d/l) и напечатать кадры (только в терминал).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local MK = dofile("build/l2d/mk.lua")
local d = dofile(arg[1]); if d.rows then d = MK.build(d.rows, d.opts) end
local lvl = R.compile(d)
local st = R.newState(lvl)
local DIR = { u = 1, r = 2, d = 3, l = 4 }
local function show(s, label)
  local rows = {}
  for y = 1, lvl.H do rows[y] = {} for x = 1, lvl.W do local c = lvl.cell[(y-1)*lvl.W+x]; rows[y][x] = c == 1 and "#" or (c == 2 and "~" or ".") end end
  for q, pp in ipairs(lvl.pieces) do if s.pos[q] ~= 0 then local x, y = R.xy(lvl, s.pos[q]); local ch = ({ source = "S", fixture = "F", stub = "T", fitting = "b", porcelain = "P", pipe = "=" })[pp.kind]; if pp.movable then ch = s.fixed[q] and "B" or "b" end; rows[y][x] = ch end end
  if not s.dead then for i, c in ipairs(s.body) do local x, y = R.xy(lvl, c); rows[y][x] = (i == #s.body) and "H" or ((i == 1) and "f" or "o") end end
  print(label); for y = 1, lvl.H do print(table.concat(rows[y])) end
end
show(st, "start")
for i = 2, #arg do
  local m = arg[i]
  local which = m:sub(1, 1) == "f" and "heel" or "head"
  local ns, kind = R.move(lvl, st, which, DIR[m:sub(2, 2)])
  if not ns then print(m .. ": отказ (" .. tostring(kind) .. ")") else st = ns; show(st, (i - 1) .. " " .. m .. " " .. kind .. (R.isWin(lvl, st) and " WIN" or "")) end
end
