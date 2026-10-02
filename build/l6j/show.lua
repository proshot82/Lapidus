-- build/l6j/show.lua файл.lua [from] [to] — кадры кратчайшего решения с номерами строк (только вывод инструмента).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local path, x = {}, G.firstWin
while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
table.insert(path, 1, 1)
local SYM = { source = "S", fixture = "F", stub = "T", pipe = "=", fitting = "b", porcelain = "P" }
local from, to = tonumber(arg[2] or 1), tonumber(arg[3] or #path)
for i = from, math.min(to, #path) do
  local s = R.decode(lvl, G.keys[path[i]])
  local rows = {}
  for y = 1, lvl.H do rows[y] = {} for x = 1, lvl.W do local c = lvl.cell[(y-1)*lvl.W+x]; rows[y][x] = c == 1 and "#" or (c == 2 and "~" or ".") end end
  for q, pp in ipairs(lvl.pieces) do if s.pos[q] ~= 0 then local x, y = R.xy(lvl, s.pos[q]); local ch = SYM[pp.kind]; if pp.movable then ch = s.fixed[q] and ch:upper() or ch:lower() end; rows[y][x] = ch end end
  for k, c in ipairs(s.body) do local x, y = R.xy(lvl, c); rows[y][x] = (k == #s.body) and "H" or ((k == 1) and "f" or "o") end
  print((i - 1) .. (i > 1 and (" " .. R.moveName(G.pmove[path[i]])) or " start"))
  for y = 1, lvl.H do print(string.format("%2d %s", y, table.concat(rows[y]))) end
end
