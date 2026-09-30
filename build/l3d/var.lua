-- build/l3d/var.lua база.lua "ряд1|ряд2|..." — метрики варианта сетки (карман 4 и 5, замуровка). Без ходов.
package.path = "./?.lua;" .. package.path
local M = dofile("build/l3d/m.lua")
local SV = require("solver.solve")
local d = dofile(arg[1])
local g = {}
for r in arg[2]:gmatch("[^|]+") do g[#g + 1] = r end
d.grid = g
print("карман4: " .. M.fmt(M.run(d, 4)))
print("карман5: " .. M.fmt(M.run(d, 5)))
local a = SV.ablations(d, { cap = 3000000 })
local t = {}
for _, x in ipairs(a) do if x.solvable ~= false then t[#t + 1] = x.name end end
print("абляции решаемы: " .. (#t > 0 and table.concat(t, ", ") or "нет"))
