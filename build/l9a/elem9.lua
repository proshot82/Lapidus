-- build/l9a/elem9.lua файл.lua — замуровка элементов g18: элемент убран (клетка пуста или стена). Только метрики.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local path = arg[1]
local function variant(label, mut)
  local d = dofile(path); mut(d); d.ablations = {}; d.controls = {}
  local ok, lvl = pcall(R.compile, d)
  if not ok or #R.validate(lvl) > 0 then print(label .. ": не компилируется → нерешаем") return end
  local G = SV.explore(lvl, 3000000)
  print(string.format("%s: %s (n=%d)", label, G.firstWin and ("решаем за " .. G.depth[G.firstWin]) or "НЕРЕШАЕМ → несущий", G.n))
  SV.freeGraph(G); io.stdout:flush()
end
local function removeTag(d, tag, wall)
  for i, o in ipairs(d.objects) do if o.tag == tag then
    if wall then local x, y = o.at[1], o.at[2]; d.grid[y] = d.grid[y]:sub(1, x - 1) .. "#" .. d.grid[y]:sub(x + 1) end
    table.remove(d.objects, i) break end end
end
variant("без ниппеля (клетка пуста)", function(d) removeTag(d, "nip", false) end)
variant("отвод под карнизом → стена", function(d) removeTag(d, "stubL", true) end)
variant("отвод под карнизом → пусто (без пола у края карниза)", function(d) removeTag(d, "stubL", false) end)
variant("отвод под площадкой → стена", function(d) removeTag(d, "stubT", true) end)
variant("труба унитаза → стена", function(d) removeTag(d, "p1", true) end)
variant("дальняя клетка гребёнки без выхода вправо", function(d) for _, o in ipairs(d.objects) do if o.tag == "m2" then o.ports.right = nil end end end)
