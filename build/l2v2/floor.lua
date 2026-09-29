-- build/l2v2/floor.lua — k4: почему клетки дна колодца не «мёртвое пространство» (что меняется в абляциях). Без ходов.
package.path = "./?.lua;" .. package.path
local R = require("core.rules"); local SV = require("solver.solve")
local base = dofile("build/l2e/k4.lua")
for _, c in ipairs({ { 4, 7 }, { 5, 7 }, { 6, 7 }, { 4, 8 }, { 5, 8 }, { 6, 8 }, { 4, 9 }, { 5, 9 }, { 6, 9 } }) do
  local d = SV.deepcopy(base); d.grid[c[2]] = d.grid[c[2]]:sub(1, c[1] - 1) .. "#" .. d.grid[c[2]]:sub(c[1] + 1)
  local t = {}; for _, a in ipairs(SV.ablations(d, { cap = 3000000 })) do t[#t + 1] = a.name .. "=" .. (a.solvable == false and "нерешаем" or "РЕШАЕМ") end
  print(string.format("(%d,%d): %s", c[1], c[2], table.concat(t, ", ")))
end
