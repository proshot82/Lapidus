-- build/l4e/walls.lua файл.lua — замуровка по одной пустой клетке: метрики каждого варианта (без ходов).
-- Клетки, без которых решение (ходы, кратчайших, абляции) не меняется, — мёртвое пространство (§7, 30.09).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local def0 = dofile(arg[1])
local function metrics(def, withAbl)
  local lvl = R.compile(def)
  if #R.validate(lvl) > 0 then return "невалиден" end
  local G = SV.explore(lvl, 3000000)
  if not G then return "CAP" end
  if not G.firstWin then local n = G.n; SV.freeGraph(G); return string.format("НЕРЕШАЕМ (%d сост.)", n) end
  local good = SV.goodSet(G)
  local VL = V.compute(lvl, G, def, good)
  local m = V.measure(G, good, VL.newbie)
  local nwin = 0; for i = 1, G.n do if G.flag[i] == 1 then nwin = nwin + 1 end end
  local sx = require("solver.strict").check(def, 3000000)
  local s = string.format("ходов %2d сост. %6d выигр. %d скрытых %4.1f %% обезьяна %.3f глубина %2d [%s] кратч %d шир %d", m.opt, G.n, nwin, m.hiddenPct, m.smart, m.maxDeep, m.deepList, sx and sx.shortest or -1, sx and sx.maxWidth or -1)
  SV.freeGraph(G); require("ffi").C.free(good)
  if withAbl then
    local ab = {}
    for _, x in ipairs(SV.ablations(def, { cap = 3000000 })) do ab[#ab + 1] = (x.solvable == false) and "н" or "Р" end
    s = s .. " абл " .. table.concat(ab)
  end
  return s
end
print("исходный:        " .. metrics(def0, true)); io.flush()
local occ = {}
for _, o in ipairs(def0.objects) do if o.at then occ[o.at[1] .. "," .. o.at[2]] = true end; if o.cells then for _, c in ipairs(o.cells) do occ[c[1] .. "," .. c[2]] = true end end end
for y = 1, #def0.grid do for x = 1, #def0.grid[1] do
  if def0.grid[y]:sub(x, x) == "." and not occ[x .. "," .. y] then
    local def = SV.deepcopy(def0)
    def.grid[y] = def.grid[y]:sub(1, x - 1) .. "#" .. def.grid[y]:sub(x + 1)
    local ok, r = pcall(metrics, def, true)
    print(string.format("стена в (%d,%d): %s", x, y, ok and r or ("ошибка " .. tostring(r)))); io.flush()
  end
end end
