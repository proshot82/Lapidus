-- var.lua база.lua "x,y;x,y" [...] — локальная доводка: поставить стены в клетки и прогнать ворота (без решений).
package.path = "./?.lua;" .. package.path
io.stdout:setvbuf("line")
local GT = dofile("build/l6c/e_orientation/gates.lua")
local base = arg[1]
for i = 2, #arg do
  local def = dofile(base)
  for xy in arg[i]:gmatch("[^;]+") do
    local x, y = xy:match("(%d+),(%d+)"); x, y = tonumber(x), tonumber(y)
    local r = def.grid[y]; def.grid[y] = r:sub(1, x - 1) .. "#" .. r:sub(x + 1)
  end
  local r = GT.eval(def, { noabl = true })
  print(arg[i] .. ": " .. r.line .. " | провалы: " .. table.concat(r.fails, ","))
end
