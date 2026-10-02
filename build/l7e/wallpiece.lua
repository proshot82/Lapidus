-- build/l7e/wallpiece.lua файл.lua — проверка «замуровать каждый элемент»: без каждой детали и с каждой деталью,
-- заменённой стеной; для каждого варианта — решаем ли, ходов, скрытых, абляции те же ли (по check-метрикам).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local def0 = dofile(arg[1])
local function metrics(def)
  local lvl = R.compile(def)
  local G = SV.explore(lvl, 3000000)
  if not G then return "CAP" end
  if not G.firstWin then local n = G.n; SV.freeGraph(G); return string.format("НЕРЕШАЕМ (%d сост.)", n) end
  local good = SV.goodSet(G)
  local VL = V.compute(lvl, G, def, good)
  local m = V.measure(G, good, VL.newbie)
  local nwin = 0; for i = 1, G.n do if G.flag[i] == 1 then nwin = nwin + 1 end end
  local s = string.format("ходов %2d сост. %6d выигр. %d скрытых %4.1f %% обезьяна %.3f глубина %2d", m.opt, G.n, nwin, m.hiddenPct, m.smart, m.maxDeep)
  SV.freeGraph(G); require("ffi").C.free(good)
  return s
end
print("исходный: " .. metrics(def0))
for i, o in ipairs(def0.objects) do
  if o.kind == "fitting" then
    local d = SV.deepcopy(def0); d.ablations = nil
    table.remove(d.objects, i)
    print(string.format("без %-5s (клетка пуста):  %s", o.tag, metrics(d)))
    local d2 = SV.deepcopy(def0); d2.ablations = nil
    table.remove(d2.objects, i)
    local x, y = o.at[1], o.at[2]
    d2.grid[y] = d2.grid[y]:sub(1, x - 1) .. "#" .. d2.grid[y]:sub(x + 1)
    print(string.format("без %-5s (клетка — стена): %s", o.tag, metrics(d2)))
  end
end
