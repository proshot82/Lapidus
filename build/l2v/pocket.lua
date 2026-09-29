-- build/l2v/pocket.lua — что за «скрытый» карман: сколько клеток, есть ли выход, сколько ходов до смерти. Только метрики.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1]); local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000); local good = SV.goodSet(G)
local hid, cells, hx, fx, nh = {}, {}, {}, {}, 0
for i = 1, G.n do if G.flag[i] ~= 2 and good[i] ~= 1 then
  local st = R.decode(lvl, G.keys[i])
  if not (def.visibleLoss and def.visibleLoss(lvl, st)) then hid[i] = true; nh = nh + 1
    for _, c in ipairs(st.body) do cells[c] = true end
    hx[st.body[#st.body]] = true; fx[st.body[1]] = true end end end
local function cnt(t) local k = 0; for _ in pairs(t) do k = k + 1 end; return k end
local mh = 0; for c in pairs(hx) do local _, y = R.xy(lvl, c); if y > mh then mh = y end end
local minY = 99; for c in pairs(cells) do local _, y = R.xy(lvl, c); if y < minY then minY = y end end
print(string.format("скрытых %d: занимают клеток %d, клеток головы %d, клеток ног %d, самая высокая строка тела %d", nh, cnt(cells), cnt(hx), cnt(fx), minY))
-- из скрытых: выходы — только смерть? доли ходов
local toDeath, toHid, toVis = 0, 0, 0
for i in pairs(hid) do for e = G.eStart.p[i-1], G.eStart.p[i]-1 do local j = G.edges.p[e]
  if G.flag[j] == 2 then toDeath = toDeath + 1 elseif hid[j] then toHid = toHid + 1 else toVis = toVis + 1 end end end
print(string.format("ходы из скрытых: внутрь кармана %d, в смыв %d, прочие %d", toHid, toDeath, toVis))
-- «время до осознания»: сколько ходов игрок может делать в кармане, не умирая, — длиннейший путь без повторов оценим как размер цикла; эксцентриситет по BFS
local maxEcc = 0
for i in pairs(hid) do local d, q, h = { [i] = 0 }, { i }, 1
  while h <= #q do local u = q[h]; h = h + 1
    for e = G.eStart.p[u-1], G.eStart.p[u]-1 do local v = G.edges.p[e]; if hid[v] and not d[v] then d[v] = d[u] + 1; if d[v] > maxEcc then maxEcc = d[v] end; q[#q+1] = v end end end end
print("наибольшее BFS-расстояние внутри кармана: " .. maxEcc)
-- сильная связность кармана: можно ли ходить туда-обратно (обратимо)
local rev = 0; for i in pairs(hid) do for e = G.eStart.p[i-1], G.eStart.p[i]-1 do local j = G.edges.p[e]
  if hid[j] then local back = false; for e2 = G.eStart.p[j-1], G.eStart.p[j]-1 do if G.edges.p[e2] == i then back = true end end; if back then rev = rev + 1 end end end end
print(string.format("обратимых рёбер внутри кармана: %d из %d", rev, toHid))
