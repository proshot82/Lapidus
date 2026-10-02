-- build/l9v/elem.lua файл.lua — замуровка элементов: деталь/закреплённый элемент убран (клетка — стена или пусто).
local L = dofile("build/l9v/lib.lua")
local R, SV = L.R, L.SV
local path = arg[1]
local function variant(label, mut)
  local d = dofile(path)
  mut(d)
  d.ablations = {}
  local lvl = R.compile(d)
  local errs = R.validate(lvl)
  if #errs > 0 then print(label .. ": ОШИБКИ " .. table.concat(errs, ";")) return end
  local G = SV.explore(lvl, 3000000)
  print(string.format("%s: %s (n=%d)", label, G.firstWin and ("решаем за " .. G.depth[G.firstWin]) or "НЕРЕШАЕМ → несущий", G.n))
  SV.freeGraph(G)
  io.stdout:flush()
end
local function removeAt(d, x, y, wall)
  for i, o in ipairs(d.objects) do if o.at and o.at[1] == x and o.at[2] == y then table.remove(d.objects, i) break end end
  if wall then d.grid[y] = d.grid[y]:sub(1, x - 1) .. "#" .. d.grid[y]:sub(x + 1) end
end
variant("без ниппеля (клетка пуста)", function(d) removeAt(d, 4, 8, false) end)
variant("глухой отвод → стена", function(d) removeAt(d, 9, 8, true) end)
variant("труба унитаза → стена", function(d) removeAt(d, 10, 7, true) end)
