-- build/l4v/variants.lua — групповые замуровки и длины Лапидуса (метрики без ходов).
package.path = "./?.lua;" .. package.path
local SV = require("solver.solve")
local MT = dofile("build/l4v/metrics.lua")
local def0 = dofile("build/l4d/k29.lua")
local function wall(d, cells)
  for _, c in ipairs(cells) do local x, y = c[1], c[2]; d.grid[y] = d.grid[y]:sub(1, x - 1) .. "#" .. d.grid[y]:sub(x + 1) end
  return d
end
local V = {
  { "правый колодец (10,4-6)+(9,4)", function(d) return wall(d, { {10,4},{10,5},{10,6},{9,4} }) end },
  { "правый колодец (10,4-6)", function(d) return wall(d, { {10,4},{10,5},{10,6} }) end },
  { "то же + (9,3)", function(d) return wall(d, { {10,4},{10,5},{10,6},{9,4},{9,3} }) end },
  { "верхний ряд (3..5,2)", function(d) return wall(d, { {3,2},{4,2},{5,2} }) end },
  { "(4,2)+(5,2)", function(d) return wall(d, { {4,2},{5,2} }) end },
  { "отвод (5,4)→стена + правый колодец", function(d)
      for i, o in ipairs(d.objects) do if o.kind == "stub" and o.at[1] == 5 then table.remove(d.objects, i) break end end
      return wall(d, { {5,4},{10,4},{10,5},{10,6},{9,4} }) end },
  { "длина 2–4", function(d) d.length = { 2, 4 } return d end },
  { "длина 3–3", function(d) d.length = { 3, 3 } return d end },
  { "длина 2–2", function(d) d.length = { 2, 2 } return d end },
  { "длина 2–5", function(d) d.length = { 2, 5 } return d end },
  { "длина 3–4", function(d) d.length = { 3, 4 } return d end },
}
for _, v in ipairs(V) do
  local d = v[2](SV.deepcopy(def0))
  local r = MT.run(d)
  print(string.format("%-36s %s", v[1], MT.fmt(r)))
  if r.solvable and arg[1] == "abl" then
    local ab = SV.ablations(d, { cap = 3000000 })
    local t = {}
    for _, a in ipairs(ab) do t[#t + 1] = a.name .. "=" .. tostring(a.solvable) end
    print("    абляции: " .. table.concat(t, ", "))
  end
end
