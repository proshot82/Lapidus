-- build/l9v2/elem.lua файл.lua — замуровка элементов g18: элемент убран (клетка — стена или пусто); решаем ли, длина,
-- скрытых по разметке файла. Решение не печатается.
local L = dofile("build/l9v2/lib.lua")
local R, SV, V = L.R, L.SV, L.V
local path = arg[1]
local function variant(label, mut)
  local d = dofile(path)
  mut(d)
  d.ablations = {}
  local lvl = R.compile(d)
  local errs = R.validate(lvl)
  if #errs > 0 then print(label .. ": ОШИБКИ " .. table.concat(errs, ";")) return end
  local G = SV.explore(lvl, 3000000)
  if not G.firstWin then print(string.format("%s: НЕРЕШАЕМ → несущий (n=%d)", label, G.n)); SV.freeGraph(G); return end
  local good = SV.goodSet(G)
  local VL = V.compute(lvl, G, d, good)
  local m = V.measure(G, good, VL.newbie)
  print(string.format("%s: решаем за %d (n=%d), скрытых %.1f %%, глубина у пути [%s]", label, G.depth[G.firstWin], G.n, m.hiddenPct, m.deepList))
  SV.freeGraph(G); require("ffi").C.free(good)
  io.stdout:flush()
end
local function removeTag(d, tag, wall)
  for i, o in ipairs(d.objects) do if o.tag == tag then
    local x, y = o.at[1], o.at[2]
    table.remove(d.objects, i)
    if wall then d.grid[y] = d.grid[y]:sub(1, x - 1) .. "#" .. d.grid[y]:sub(x + 1) end
    return end end
end
variant("глухой отвод под карнизом (stubL) → стена", function(d) removeTag(d, "stubL", true) end)
variant("глухой отвод под карнизом (stubL) → пусто", function(d) removeTag(d, "stubL", false) end)
variant("отвод под гнездом (stubT) → стена", function(d) removeTag(d, "stubT", true) end)
variant("без ниппеля", function(d) removeTag(d, "nip", false) end)
variant("у гребёнки нет выхода вправо в линию унитаза (m2 right убран)", function(d) for _, o in ipairs(d.objects) do if o.tag == "m2" then o.ports.right = nil end end end)
