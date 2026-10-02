-- build/l8a/doors.lua файл.lua — все двери живое→скрытое (новичок), сгруппированные по переходу раскладки:
-- число рёбер, мин. глубина исходного состояния от старта, лежит ли исходное на кратчайшем пути, хвост скрытой области. Только терминал.
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
local ES, E, flag, n = G.eStart.p, G.edges.p, G.flag, G.n
local function cfg(s)
  local t = {}
  for q, p in ipairs(lvl.pieces) do if p.movable then
    if s.pos[q] == 0 then t[#t+1] = p.tag .. "=смыт" else
    local x, y = R.xy(lvl, s.pos[q]); t[#t+1] = string.format("%s(%d,%d)%s", p.tag, x, y, s.fixed[q] and "F" or "") end end end
  return table.concat(t, " ")
end
-- расстояние до победы
local cnt = {}; for i = 1, n + 1 do cnt[i] = 0 end
for i = 1, n do for e = ES[i-1], ES[i]-1 do local j = E[e]; cnt[j] = cnt[j] + 1 end end
local st, s = {}, 1; for i = 1, n do st[i] = s; s = s + cnt[i] end; st[n+1] = s
local fill, rv = {}, {}; for i = 1, n do fill[i] = st[i] end
for i = 1, n do for e = ES[i-1], ES[i]-1 do local j = E[e]; rv[fill[j]] = i; fill[j] = fill[j] + 1 end end
local dw, q, h = {}, {}, 1
for i = 1, n do if flag[i] == 1 then dw[i] = 0; q[#q+1] = i end end
while h <= #q do local j = q[h]; h = h + 1; for k = st[j], st[j+1]-1 do local i = rv[k]; if dw[i] == nil then dw[i] = dw[j] + 1; q[#q+1] = i end end end
local function tail(j)
  local d, qq, hh, maxd = { [j] = 0 }, { j }, 1, 0
  while hh <= #qq do local u = qq[hh]; hh = hh + 1
    for e = ES[u-1], ES[u]-1 do local v = E[e]; if m.hidden[v] and d[v] == nil then d[v] = d[u]+1; if d[v] > maxd then maxd = d[v] end; qq[#qq+1] = v end end end
  return maxd, #qq
end
local agg = {}
for i = 1, n do if good[i] == 1 and flag[i] == 0 then
  for e = ES[i-1], ES[i]-1 do local j = E[e]
    if m.hidden[j] then
      local k = cfg(VL.states[i]) .. " → " .. cfg(VL.states[j])
      local a = agg[k] or { n = 0, minD = 1e9, onpath = false, tail = 0, sz = 0, offby = 1e9 }; agg[k] = a
      a.n = a.n + 1
      if G.depth[i] < a.minD then a.minD = G.depth[i] end
      local off = G.depth[i] + dw[i] - m.opt; if off < a.offby then a.offby = off end
      if off == 0 then a.onpath = true end
      if a.tail == 0 then a.tail, a.sz = tail(j) end
    end end end end
local l = {}
for k, a in pairs(agg) do l[#l+1] = { k, a } end
table.sort(l, function(x, y) if x[2].offby ~= y[2].offby then return x[2].offby < y[2].offby end return x[2].n > y[2].n end)
print(string.format("ходов %d; переходов живое→скрытое: %d типов", m.opt, #l))
for i = 1, math.min(30, #l) do local a = l[i][2]
  print(string.format("  %s глуб %2d (+%d от пути) рёбер %3d хвост %2d/%5d  %s", a.onpath and "ПУТЬ" or "    ", a.minD, a.offby, a.n, a.tail, a.sz, l[i][1])) end
SV.freeGraph(G); require("ffi").C.free(good)
