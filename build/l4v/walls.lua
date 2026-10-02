-- build/l4v/walls.lua — замуровать по одной пустой клетке / убрать отвод; метрики каждого варианта (без ходов).
package.path = "./?.lua;" .. package.path
local SV = require("solver.solve")
local MT = dofile("build/l4v/metrics.lua")
local file = arg[1] or "build/l4d/k29.lua"
local def0 = dofile(file)
local occ = {}
for _, o in ipairs(def0.objects) do
  if o.at then occ[o.at[1] .. "," .. o.at[2]] = true end
  if o.cells then for _, c in ipairs(o.cells) do occ[c[1] .. "," .. c[2]] = true end end
end
print("исходный: " .. MT.fmt(MT.run(def0)))
for i, o in ipairs(def0.objects) do
  if o.kind == "stub" then
    local d = SV.deepcopy(def0); table.remove(d.objects, i)
    print(string.format("без отвода (%d,%d): %s", o.at[1], o.at[2], MT.fmt(MT.run(d))))
  end
end
if arg[2] == "stubs" then return end
for y = 1, #def0.grid do
  for x = 1, #def0.grid[1] do
    if def0.grid[y]:sub(x, x) == "." and not occ[x .. "," .. y] then
      local d = SV.deepcopy(def0)
      d.grid[y] = d.grid[y]:sub(1, x - 1) .. "#" .. d.grid[y]:sub(x + 1)
      io.write(string.format("стена (%d,%d): %s\n", x, y, MT.fmt(MT.run(d, true)))); io.flush()
    end
  end
end
