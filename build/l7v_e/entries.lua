-- build/l7v_e/entries.lua файл.lua — все переходы живое→скрытое по конфигурациям деталей (классы ошибок), с глубиной хвоста и расстоянием от старта
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
local function cfg(s) local t={} for _,q in ipairs({Q.elb,Q.plug}) do local x,y=R.xy(lvl,s.pos[q]); t[#t+1]=string.format("%d,%d%s",x,y,s.fixed[q] and "F" or "") end return table.concat(t," ") end
local function depthFrom(j)
  local d, q, h, maxd = { [j] = 0 }, { j }, 1, 0
  while h <= #q do local u = q[h]; h = h + 1
    for e = G.eStart.p[u-1], G.eStart.p[u]-1 do local v = G.edges.p[e]
      if m.hidden[v] and d[v] == nil then d[v] = d[u]+1; if d[v] > maxd then maxd = d[v] end; q[#q+1] = v end end end
  return maxd
end
local agg = {}
for i = 1, G.n do if good[i] == 1 then
  for e = G.eStart.p[i-1], G.eStart.p[i]-1 do local j = G.edges.p[e]
    if m.hidden[j] then local k = cfg(VL.states[i]) .. " → " .. cfg(VL.states[j])
      local a = agg[k] or { 0, 0, 999 }; agg[k] = a; a[1] = a[1] + 1; local d = depthFrom(j); if d > a[2] then a[2] = d end; if G.depth[i] < a[3] then a[3] = G.depth[i] end end end end end
for k, a in pairs(agg) do print(string.format("%-28s переходов %3d, хвост до %2d, ближайший на глубине %d", k, a[1], a[2], a[3])) end
