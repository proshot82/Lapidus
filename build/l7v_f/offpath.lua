-- build/l7v_f/offpath.lua файл.lua — для каждого класса скрытых входов: минимальное удаление живого источника
-- от множества кратчайших путей (в живых ходах) и глубина скрытой ветки. Печать без ходов.
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
local function cfg(s)
  local t = {}
  for q, p in ipairs(lvl.pieces) do if p.movable then
    local x, y = R.xy(lvl, s.pos[q]); t[#t+1] = string.format("%s(%d,%d)%s%s", p.tag, x, y, s.fixed[q] and "F" or "", "a"..s.asm[q]) end end
  return table.concat(t, " ")
end
-- dist to win
local cnt = {} for i = 1, n + 1 do cnt[i] = 0 end
for i = 1, n do for e = ES[i-1], ES[i]-1 do cnt[E[e]] = cnt[E[e]] + 1 end end
local st, s = {}, 1 for i = 1, n do st[i] = s; s = s + cnt[i] end st[n+1] = s
local fill, rv = {}, {} for i = 1, n do fill[i] = st[i] end
for i = 1, n do for e = ES[i-1], ES[i]-1 do local j = E[e]; rv[fill[j]] = i; fill[j] = fill[j] + 1 end end
local dw, q, h = {}, {}, 1
for i = 1, n do if flag[i] == 1 then dw[i] = 0; q[#q+1] = i end end
while h <= #q do local j = q[h]; h = h + 1; for k = st[j], st[j+1]-1 do local i = rv[k]; if dw[i] == nil then dw[i] = dw[j] + 1; q[#q+1] = i end end end
local opt = G.depth[G.firstWin]
-- удаление от кратчайших: BFS по живым ходам от всех состояний кратчайших путей
local off, qq = {}, {}
for i = 1, n do if dw[i] and G.depth[i] + dw[i] == opt then off[i] = 0; qq[#qq+1] = i end end
h = 1
while h <= #qq do local u = qq[h]; h = h + 1
  for e = ES[u-1], ES[u]-1 do local v = E[e]; if good[v] == 1 and off[v] == nil then off[v] = off[u] + 1; qq[#qq+1] = v end end end
local function hidden(j) return flag[j] == 0 and good[j] ~= 1 and not VL.newbie[j] end
local function region(j)
  local d, qx, hx, maxd = { [j] = 0 }, { j }, 1, 0
  while hx <= #qx do local u = qx[hx]; hx = hx + 1
    for e = ES[u-1], ES[u]-1 do local v = E[e]; if hidden(v) and d[v] == nil then d[v] = d[u] + 1; if d[v] > maxd then maxd = d[v] end; qx[#qx+1] = v end end end
  return maxd
end
local agg = {}
for i = 1, n do if good[i] == 1 and flag[i] == 0 then
  for e = ES[i-1], ES[i]-1 do local j = E[e]
    if hidden(j) then local k = cfg(R.decode(lvl, G.keys[j]))
      local a = agg[k] or { n = 0, off = 99, deep = 0, ph = 99 }; agg[k] = a
      a.n = a.n + 1; if (off[i] or 99) < a.off then a.off = off[i] or 99 end
      local d = region(j); if d > a.deep then a.deep = d end
      if G.depth[i] < a.ph then a.ph = G.depth[i] end
    end end end end
local l = {} for k, a in pairs(agg) do l[#l+1] = { k, a } end
table.sort(l, function(x, y) return x[2].off < y[2].off end)
print("вход в скрытое: удаление от кратчайших (живых ходов) | входов | глубина | мин. номер хода от старта | класс")
for _, e in ipairs(l) do print(string.format("  уд %2d  вх %4d  гл %2d  ход≥%2d  %s", e[2].off, e[2].n, e[2].deep, e[2].ph, e[1])) end
local hist = {}
for i, d in pairs(off) do hist[d] = (hist[d] or 0) + 1 end
local t = {} for d = 0, 40 do if hist[d] then t[#t+1] = d .. ":" .. hist[d] end end
print("живые по удалению от кратчайших: " .. table.concat(t, " "))
SV.freeGraph(G); require("ffi").C.free(good)
