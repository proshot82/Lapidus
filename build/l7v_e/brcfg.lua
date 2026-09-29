-- build/l7v_e/brcfg.lua файл.lua — из каких конфигураций деталей состоят скрытые ветки у кратчайшего пути (+ глубина до выхода в класс)
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local VL = V.compute(lvl, G, def, good)
local m = V.measure(G, good, VL.newbie)
local Q = {}; for q, p in ipairs(lvl.pieces) do if p.tag then Q[p.tag] = q end end
local E, P = Q.elb, Q.plug
local function cfg(s) local t={} for _,q in ipairs({E,P}) do local x,y=R.xy(lvl,s.pos[q]); t[#t+1]=string.format("%d,%d%s",x,y,s.fixed[q] and "F" or "") end return table.concat(t," ") end
local done = {}
for k = 1, #m.path - 1 do
  local s = m.path[k]
  for e = G.eStart.p[s-1], G.eStart.p[s]-1 do local j = G.edges.p[e]
    if m.hidden[j] and not done[j] then done[j] = true
      local d, q, h = { [j] = 0 }, { j }, 1
      while h <= #q do local u = q[h]; h = h + 1
        for ee = G.eStart.p[u-1], G.eStart.p[u]-1 do local v = G.edges.p[ee]
          if m.hidden[v] and d[v] == nil then d[v] = d[u]+1; q[#q+1] = v end end end
      local agg = {}
      for _, u in ipairs(q) do local c = cfg(VL.states[u]); local a = agg[c] or { 0, 99, 0 }; agg[c] = a; a[1] = a[1]+1; if d[u] < a[2] then a[2] = d[u] end; if d[u] > a[3] then a[3] = d[u] end end
      print(string.format("ветка у шага %d: %d состояний, входная конфигурация %s", k-1, #q, cfg(VL.states[j])))
      for c, a in pairs(agg) do print(string.format("   %-14s %5d сост., глубина первого появления %2d, макс %2d", c, a[1], a[2], a[3])) end
    end
  end
end
