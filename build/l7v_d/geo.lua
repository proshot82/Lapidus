-- build/l7v_d/geo.lua — роль пустого пространства: варианты раскладки с заделанными клетками (решаемость, ходов, состояний,
-- скрытых по общей линейке). Только метрики, без ходов.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local base = "build/l7c/d_tee_lift/L7D.lua"
local function variant(name, edit)
  local def = dofile(base)
  edit(def)
  local lvl = R.compile(def)
  local errs = R.validate(lvl)
  if #errs > 0 then print(name .. ": ОШИБКИ " .. table.concat(errs, "; ")) return end
  local G = SV.explore(lvl, 3000000)
  if not G then print(name .. ": CAP") return end
  if not G.firstWin then print(string.format("%-46s нерешаем (состояний %d)", name, G.n)) SV.freeGraph(G) return end
  local good = SV.goodSet(G)
  local VL = V.compute(lvl, G, def, good)
  local M = V.measure(G, good, VL.newbie)
  print(string.format("%-46s ходов %d | состояний %d | скрытых %.0f %% | обезьяна %.2f %% | глубина %d", name, G.depth[G.firstWin], G.n, M.hiddenPct, M.smart, M.maxDeep))
  SV.freeGraph(G); require("ffi").C.free(good)
end
local function setCell(def, x, y, ch) local row = def.grid[y]; def.grid[y] = row:sub(1, x - 1) .. ch .. row:sub(x + 1) end
variant("исходник", function() end)
variant("ниша (4,3) заделана", function(d) setCell(d, 4, 3, "#") end)
variant("корыто (8..11,8) заделано", function(d) for x = 8, 11 do setCell(d, x, 8, "#") end end)
variant("корыто заделано + ниша заделана", function(d) for x = 8, 11 do setCell(d, x, 8, "#") end; setCell(d, 4, 3, "#") end)
variant("правый столбец x=11 заделан", function(d) for y = 2, 8 do setCell(d, 11, y, "#") end end)
variant("столбцы x=10..11 заделаны", function(d) for y = 2, 8 do setCell(d, 10, y, "#"); setCell(d, 11, y, "#") end end)
variant("столбцы x=9..11 заделаны", function(d) for y = 2, 8 do for x = 9, 11 do setCell(d, x, y, "#") end end end)
variant("верхний ряд y=2 заделан", function(d) for x = 5, 11 do setCell(d, x, 2, "#") end end)
variant("ряд y=2 при x>=7 заделан", function(d) for x = 7, 11 do setCell(d, x, 2, "#") end end)
variant("угол (2,6) заделан", function(d) setCell(d, 2, 6, "#") end)
variant("(3,5) заделана", function(d) setCell(d, 3, 5, "#") end)
