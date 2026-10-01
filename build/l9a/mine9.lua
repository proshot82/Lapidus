-- build/l9a/mine9.lua файл.lua — «минное поле» (скептик кв. 7): ходы в проигрыш по шагам кратчайших путей и по всем живым.
-- минное поле: по состояниям кратчайших путей — ходов всего / в живое / в скрытое / в видимое; по всем живым — доля ходов в проигрыш
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
local cnt = {} for i = 1, n + 1 do cnt[i] = 0 end
for i = 1, n do for e = ES[i-1], ES[i]-1 do cnt[E[e]] = cnt[E[e]] + 1 end end
local st, s = {}, 1 for i = 1, n do st[i] = s; s = s + cnt[i] end st[n+1] = s
local fill, rv = {}, {} for i = 1, n do fill[i] = st[i] end
for i = 1, n do for e = ES[i-1], ES[i]-1 do local j = E[e]; rv[fill[j]] = i; fill[j] = fill[j] + 1 end end
local dw, q, h = {}, {}, 1
for i = 1, n do if flag[i] == 1 then dw[i] = 0; q[#q+1] = i end end
while h <= #q do local j = q[h]; h = h + 1; for k = st[j], st[j+1]-1 do local i = rv[k]; if dw[i] == nil then dw[i] = dw[j] + 1; q[#q+1] = i end end end
local opt = G.depth[G.firstWin]
local function hid(j) return flag[j] == 0 and good[j] ~= 1 and not VL.newbie[j] end
local T = { st = 0, all = 0, live = 0, hid = 0, vis = 0 }
local perStep = {}
for i = 1, n do if flag[i] == 0 and dw[i] and G.depth[i] + dw[i] == opt then
  local d = G.depth[i]; perStep[d] = perStep[d] or { 0, 0, 0 }
  T.st = T.st + 1
  for e = ES[i-1], ES[i]-1 do local j = E[e]; T.all = T.all + 1
    if good[j] == 1 or flag[j] == 1 then T.live = T.live + 1; perStep[d][1] = perStep[d][1] + 1 elseif hid(j) then T.hid = T.hid + 1; perStep[d][2] = perStep[d][2] + 1 else T.vis = T.vis + 1; perStep[d][3] = perStep[d][3] + 1 end end
end end
local l = {}
for d = 0, opt - 1 do local p = perStep[d] or {0,0,0}; l[#l+1] = string.format("%d:%d/%d/%d", d, p[1], p[2], p[3]) end
print("по шагам (живых/скрытых/видимых ходов из состояний кратчайших путей): " .. table.concat(l, " "))
print(string.format("итого по кратчайшим: состояний %d, ходов %d, в проигрыш %d (%.1f %%), из них скрытых %d", T.st, T.all, T.hid + T.vis, 100 * (T.hid + T.vis) / T.all, T.hid))
local A = { all = 0, hid = 0, vis = 0, stN = 0, stDoor = 0 }
for i = 1, n do if flag[i] == 0 and good[i] == 1 then
  A.stN = A.stN + 1; local dd = false
  for e = ES[i-1], ES[i]-1 do local j = E[e]; A.all = A.all + 1
    if good[j] == 1 or flag[j] == 1 then elseif hid(j) then A.hid = A.hid + 1; dd = true else A.vis = A.vis + 1; dd = true end end
  if dd then A.stDoor = A.stDoor + 1 end
end end
print(string.format("все живые: состояний %d, ходов %d (%.2f на состояние), в проигрыш %.2f %% (скрытых %d, видимых %d); живых с хотя бы одной дверью %.1f %%",
  A.stN, A.all, A.all / A.stN, 100 * (A.hid + A.vis) / A.all, A.hid, A.vis, 100 * A.stDoor / A.stN))
SV.freeGraph(G); require("ffi").C.free(good)
