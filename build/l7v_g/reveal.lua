-- build/l7v_g/reveal.lua файл.lua — «стойкость» дверей: для каждого входа живое→скрытое — за сколько ходов (минимум)
-- проигрыш можно увидеть (дойти до видимого состояния), сколько скрытых состояний в радиусе 4 и 6 ходов, глубина.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local VL = V.compute(lvl, G, def, good)
local ES, E, flag, n = G.eStart.p, G.edges.p, G.flag, G.n
local function hid(j) return flag[j] == 0 and good[j] ~= 1 and not VL.newbie[j] end
local function cfg(s)
  local t = {}
  for q, p in ipairs(lvl.pieces) do if p.movable then
    local x, y = R.xy(lvl, s.pos[q]); t[#t+1] = string.format("%s(%d,%d)%s", p.tag, x, y, s.fixed[q] and "F" or "") end end
  return table.concat(t, " ")
end
local agg = {}
for i = 1, n do if flag[i] == 0 and good[i] == 1 then
  for e = ES[i-1], ES[i]-1 do local j = E[e]
    if hid(j) then
      local d, qx, hx, rev, r4, r6, maxd = { [j] = 0 }, { j }, 1, nil, 0, 0, 0
      while hx <= #qx do local u = qx[hx]; hx = hx + 1
        if d[u] <= 4 then r4 = r4 + 1 end; if d[u] <= 6 then r6 = r6 + 1 end
        for ee = ES[u-1], ES[u]-1 do local v = E[ee]
          if flag[v] == 0 and good[v] ~= 1 and VL.newbie[v] and not rev then rev = d[u] + 1 end
          if hid(v) and d[v] == nil then d[v] = d[u] + 1; if d[v] > maxd then maxd = d[v] end; qx[#qx+1] = v end end end
      local k = cfg(R.decode(lvl, G.keys[j]))
      local a = agg[k] or { n = 0, rmin = 99, rmax = 0, r4 = 0, r6 = 0, deep = 0, size = 0 }; agg[k] = a
      a.n = a.n + 1; rev = rev or 99
      a.rmin = math.min(a.rmin, rev); a.rmax = math.max(a.rmax, rev); a.r4 = math.max(a.r4, r4); a.r6 = math.max(a.r6, r6)
      a.deep = math.max(a.deep, maxd); a.size = math.max(a.size, #qx)
    end end end end
print("класс входа | входов | мин. ходов до видимого (по входам: мин–макс; 99 = никогда) | скрытых в радиусе 4 / 6 | глубина | размер области")
for k, a in pairs(agg) do print(string.format("  %-28s вх %3d  вскрытие %2d–%2d  r4 %4d r6 %5d  гл %2d  обл %5d", k, a.n, a.rmin, a.rmax, a.r4, a.r6, a.deep, a.size)) end
SV.freeGraph(G); require("ffi").C.free(good)
