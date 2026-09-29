-- build/l7v_e/lock.lua файл.lua [K] — общее правило-кандидат «детали заперты»: из скрытого тупика все достижимые
-- невидимые состояния имеют не больше K разных конфигураций деталей (Лапидус только ходит); итерация до неподвижной точки.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local def = dofile(arg[1])
local K = tonumber(arg[2] or 1)
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local VL = V.compute(lvl, G, def, good)
local cfg = {}
for i = 1, G.n do if G.flag[i] ~= 2 then local s = VL.states[i]; local t = {}
  for q = 1, #s.pos do t[#t+1] = s.pos[q] .. (s.fixed[q] and "F" or "") end; cfg[i] = table.concat(t, ",") end end
local lost = {}
for i = 1, G.n do if G.flag[i] ~= 2 then lost[i] = VL.newbie[i] end end
local base = V.measure(G, good, lost)
print(string.format("линейка: скрытых %d = %.1f %%, обезьяна %.3f, глубина %d [%s]", base.hid, base.hiddenPct, base.smart, base.maxDeep, base.deepList))
for it = 1, 20 do
  local add = 0
  local newl = {}
  for i = 1, G.n do
    if G.flag[i] ~= 2 and good[i] ~= 1 and not lost[i] then
      local set, ns, seen, q, h, ok = {}, 0, { [i] = true }, { i }, 1, true
      while h <= #q and ok do local u = q[h]; h = h + 1
        if not set[cfg[u]] then set[cfg[u]] = true; ns = ns + 1; if ns > K then ok = false end end
        for e = G.eStart.p[u-1], G.eStart.p[u]-1 do local v = G.edges.p[e]
          if G.flag[v] ~= 2 and not lost[v] and not seen[v] then seen[v] = true; q[#q+1] = v end end end
      if ok then newl[i] = true; add = add + 1 end
    end
  end
  for i in pairs(newl) do lost[i] = true end
  local m = V.measure(G, good, lost)
  print(string.format("итерация %d: +%d, скрытых %d = %.1f %%, обезьяна %.3f, глубина %d [%s]", it, add, m.hid, m.hiddenPct, m.smart, m.maxDeep, m.deepList))
  if add == 0 then break end
end
