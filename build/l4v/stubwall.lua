-- build/l4v/stubwall.lua — отвод заменить стеной (роль отвода как резьбы, а не как клетки пола).
package.path = "./?.lua;" .. package.path
local SV = require("solver.solve")
local MT = dofile("build/l4v/metrics.lua")
local def0 = dofile(arg[1] or "build/l4d/k29.lua")
for i, o in ipairs(def0.objects) do
  if o.kind == "stub" then
    local d = SV.deepcopy(def0); table.remove(d.objects, i)
    local x, y = o.at[1], o.at[2]
    d.grid[y] = d.grid[y]:sub(1, x - 1) .. "#" .. d.grid[y]:sub(x + 1)
    print(string.format("отвод (%d,%d) → стена: %s", x, y, MT.fmt(MT.run(d))))
  end
end
