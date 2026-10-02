-- build/l7j/widthdump.lua файл.lua шаг — состояния коридора кратчайших на данном шаге (кадры, только вывод инструмента)
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1]); local K = tonumber(arg[2])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local opt = G.depth[G.firstWin]
local ES, E = G.eStart.p, G.edges.p
local on = {}
for i = G.n, 1, -1 do
  if G.flag[i] == 1 and G.depth[i] == opt then on[i] = true
  elseif G.flag[i] == 0 and G.depth[i] < opt then
    for e = ES[i - 1], ES[i] - 1 do local j = E[e]; if on[j] and G.depth[j] == G.depth[i] + 1 then on[i] = true break end end
  end
end
for i = 1, G.n do if on[i] and G.depth[i] == K then
  local s = R.decode(lvl, G.keys[i])
  local rows = {}
  for y = 1, lvl.H do rows[y] = {} for x = 1, lvl.W do local c = lvl.cell[(y-1)*lvl.W+x]; rows[y][x] = c == 1 and "#" or "." end end
  for q, p in ipairs(lvl.pieces) do if s.pos[q] ~= 0 then local x, y = R.xy(lvl, s.pos[q]); rows[y][x] = p.movable and (s.fixed[q] and "B" or "b") or (p.source and "S" or "F") end end
  for k, c in ipairs(s.body) do local x, y = R.xy(lvl, c); rows[y][x] = (k == #s.body) and "H" or ((k == 1) and "f" or "o") end
  local t = {} for y = 3, lvl.H - 1 do t[#t+1] = table.concat(rows[y]) end
  print(table.concat(t, " "))
end end
