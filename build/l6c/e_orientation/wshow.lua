-- wshow.lua файл.lua шаг ["x,y;..."] — кадры всех состояний кратчайших решений на данном шаге (ТОЛЬКО вывод инструмента).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
if arg[3] then for xy in arg[3]:gmatch("[^;]+") do
  local x, y = xy:match("(%d+),(%d+)"); x, y = tonumber(x), tonumber(y)
  local r = def.grid[y]; def.grid[y] = r:sub(1, x - 1) .. "#" .. r:sub(x + 1) end end
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local opt = G.depth[G.firstWin]
local on = {}
for i = G.n, 1, -1 do
  if G.flag[i] == 1 and G.depth[i] == opt then on[i] = true
  elseif G.flag[i] == 0 and G.depth[i] < opt then
    for e = G.eStart.p[i - 1], G.eStart.p[i] - 1 do local j = G.edges.p[e]; if on[j] and G.depth[j] == G.depth[i] + 1 then on[i] = true break end end
  end
end
local step = tonumber(arg[2])
local frames = {}
for i = 1, G.n do if on[i] and G.depth[i] == step then
  local s = R.decode(lvl, G.keys[i])
  local rows = {}
  for y = 1, lvl.H do rows[y] = {} for x = 1, lvl.W do local c = lvl.cell[(y-1)*lvl.W+x]; rows[y][x] = c == 1 and "#" or (c == 2 and "~" or ".") end end
  for q, pp in ipairs(lvl.pieces) do if s.pos[q] ~= 0 then local x, y = R.xy(lvl, s.pos[q]); local ch = pp.movable and (pp.tag or "b"):sub(1,1) or (pp.source and "S" or (pp.fixture and "F" or "T")); if pp.movable and s.fixed[q] then ch = ch:upper() end; rows[y][x] = ch end end
  for k, c in ipairs(s.body) do local x, y = R.xy(lvl, c); rows[y][x] = (k == #s.body) and "H" or ((k == 1) and "f" or "o") end
  local out = {}
  for y = 1, lvl.H do out[y] = table.concat(rows[y]) end
  frames[#frames + 1] = out
end end
for y = 1, lvl.H do local parts = {} for k = 1, #frames do parts[k] = frames[k][y] .. "  " end print(table.concat(parts)) end
