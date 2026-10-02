-- wvar.lua база.lua "x,y;..." [...] — быстрый прогон вариантов стен: ширина коридора + основные ворота (без строгой обезьяны).
package.path = "./?.lua;" .. package.path
io.stdout:setvbuf("line")
local GT = dofile("build/l6c/e_orientation/gates.lua")
local ST = require("solver.strict")
for i = 2, #arg do
  local def = dofile(arg[1])
  for xy in arg[i]:gmatch("[^;]+") do
    local x, y = xy:match("(%d+),(%d+)"); x, y = tonumber(x), tonumber(y)
    local r = def.grid[y]; def.grid[y] = r:sub(1, x - 1) .. "#" .. r:sub(x + 1)
  end
  local r = GT.eval(def, { noabl = true, nostrict = true })
  local w = ""
  if not r.unsolvable and r.opt then
    local G = ST.graph(def, 3000000)
    local sh = ST.shortest(G)
    w = string.format(" | кратч. %d/ш%d", sh.count, sh.maxWidth)
  end
  print(arg[i] .. ": " .. r.line .. w .. " | провалы: " .. table.concat(r.fails, ","))
end
