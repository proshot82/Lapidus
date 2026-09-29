-- show.lua файл.lua N [N2 ...] — нарисовать состояние графа по номеру (ТОЛЬКО вывод инструмента).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local SYM = { source = "S", fixture = "F", stub = "T", pipe = "=", fitting = "b", porcelain = "P" }
local why = def.visModes and def.visModes.why
for a = 2, #arg do
  local i = tonumber(arg[a])
  local s = R.decode(lvl, G.keys[i])
  local rows = {}
  for y = 1, lvl.H do rows[y] = {} for x = 1, lvl.W do local c = lvl.cell[(y-1)*lvl.W+x]; rows[y][x] = c == 1 and "#" or (c == 2 and "~" or ".") end end
  for _, j in ipairs(R.jets(lvl, s)) do for _, c in ipairs(j.cells) do local x, y = R.xy(lvl, c); rows[y][x] = (j.dir == 1 or j.dir == 3) and "|" or "-" end end
  for q, pp in ipairs(lvl.pieces) do if s.pos[q] ~= 0 then local x, y = R.xy(lvl, s.pos[q]); local ch
    if pp.movable then ch = (pp.tag and pp.tag:sub(1,1)) or "b"; ch = s.fixed[q] and ch:upper() or ch:lower() else ch = SYM[pp.kind] end; rows[y][x] = ch end end
  for k, c in ipairs(s.body) do local x, y = R.xy(lvl, c); rows[y][x] = (k == #s.body) and "H" or ((k == 1) and "f" or "o") end
  print("#" .. i .. " глубина " .. G.depth[i] .. (why and (" разметка " .. tostring(why(lvl, s))) or ""))
  for y = 1, lvl.H do print(table.concat(rows[y])) end
end
SV.freeGraph(G)
