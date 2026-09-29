-- build/l7v_g/persist.lua файл.lua — стойкость дверей с кратчайших путей (мерка новичка A, карман 4):
-- от двери BFS внутри скрытых; за сколько ходов (минимум) игрок доводит упавшую деталь до трубы на полу (x=8, y=7) —
-- первая попытка «сунуть в фонтан снизу», после которой толчок упирается в трубу; и за сколько ходов виден проигрыш
-- по линейке. Печать — только метрики; кадры не печатаются.
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
-- обратный BFS до победы
local cnt, st, rv = {}, {}, {}
for i = 1, n + 1 do cnt[i] = 0 end
for i = 1, n do for e = ES[i-1], ES[i]-1 do cnt[E[e]] = cnt[E[e]] + 1 end end
local s = 1; for i = 1, n do st[i] = s; s = s + cnt[i] end; st[n+1] = s
local fill = {}; for i = 1, n do fill[i] = st[i] end
for i = 1, n do for e = ES[i-1], ES[i]-1 do local j = E[e]; rv[fill[j]] = i; fill[j] = fill[j] + 1 end end
local dw, q, h = {}, {}, 1
for i = 1, n do if flag[i] == 1 then dw[i] = 0; q[#q+1] = i end end
while h <= #q do local j = q[h]; h = h + 1; for k = st[j], st[j+1]-1 do local i = rv[k]; if dw[i] == nil then dw[i] = dw[j] + 1; q[#q+1] = i end end end
local opt = G.depth[G.firstWin]
local function hid(j) return flag[j] == 0 and good[j] ~= 1 and not VL.newbie[j] end
local function atPipe(j)
  local s2 = R.decode(lvl, G.keys[j])
  for qq, p in ipairs(lvl.pieces) do if p.movable and s2.pos[qq] ~= 0 and not s2.fixed[qq] then
    local x, y = R.xy(lvl, s2.pos[qq]); if x == 8 and y == 7 then return true end end end
  return false
end
local function onFloor(j)
  local s2 = R.decode(lvl, G.keys[j])
  for qq, p in ipairs(lvl.pieces) do if p.movable and s2.pos[qq] ~= 0 and not s2.fixed[qq] then
    local _, y = R.xy(lvl, s2.pos[qq]); if y == 7 then return true end end end
  return false
end
print("шаг | дверь: деталь на полу сразу? | ходов до детали у трубы (мин) | ходов до видимого по линейке (мин) | глубина")
for i = 1, n do if flag[i] == 0 and good[i] == 1 and G.depth[i] + (dw[i] or 1e9) == opt then
  for e = ES[i-1], ES[i]-1 do local j = E[e]
    if hid(j) then
      local d, qq, hh, pipeD, visD, maxd = { [j] = 0 }, { j }, 1, nil, nil, 0
      if atPipe(j) then pipeD = 0 end
      while hh <= #qq do local u = qq[hh]; hh = hh + 1
        for ee = ES[u-1], ES[u]-1 do local v = E[ee]
          if flag[v] == 0 and good[v] ~= 1 and VL.newbie[v] and not visD then visD = d[u] + 1 end
          if hid(v) and d[v] == nil then d[v] = d[u] + 1; if d[v] > maxd then maxd = d[v] end
            if not pipeD and atPipe(v) then pipeD = d[v] end; qq[#qq+1] = v end end end
      print(string.format("  %2d | %s | %s | %s | %d", G.depth[i] + 1, onFloor(j) and "да" or "нет",
        tostring(pipeD or "—"), tostring(visD or "никогда"), maxd))
    end end end end
SV.freeGraph(G); require("ffi").C.free(good)
