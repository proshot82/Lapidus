-- build/l2v3/bait.lua — k6: все рёбера живое → «прикручен к приманке» (under / under2), с падением и без;
-- откуда (на пути или нет, чем держится источник), куда (мёртвое?), когда вскрывается. Без ходов.
package.path = "./?.lua;" .. package.path
arg = { arg[1] or "build/l2e/k6.lua" }
local real = print; print = function() end
local P = dofile("build/l2v3/probe.lua"); print = real
local R = require("core.rules"); local def = dofile(arg[1]); local lvl = R.compile(def)
local sts, succ, live, dead, path = P.sts, P.succ, P.live, P.dead, P.path
local W = lvl.W
local onPath = {}; for k, i in ipairs(path) do onPath[i] = k - 1 end
local function anch(st)
  if st.dead then return {} end
  local piece = R.occupancy(st); local t = {}
  for _, w in ipairs({ "head", "heel" }) do local q = R.endScrew(lvl, st, piece, w); if q then t[lvl.pieces[q].tag or lvl.pieces[q].kind] = w end end
  return t
end
local function has(t) local r = {}; for k in pairs(t) do r[#r + 1] = k end; table.sort(r); return table.concat(r, ",") end
-- расстояние от пути (по живым, вперёд от любой вершины пути)
local dp = {}; do local q, h = {}, 1; for i in pairs(onPath) do dp[i] = 0; q[#q + 1] = i end
  while h <= #q do local u = q[h]; h = h + 1; for _, e in ipairs(succ[u]) do if live[e.j] and not dp[e.j] then dp[e.j] = dp[u] + 1; q[#q + 1] = e.j end end end end
local function bfsMax(j) local seen, q, h = { [j] = 0 }, { j }, 1; local md = 0
  while h <= #q do local u = q[h]; h = h + 1; for _, e in ipairs(succ[u]) do if dead[e.j] and not seen[e.j] then seen[e.j] = seen[u] + 1; if seen[e.j] > md then md = seen[e.j] end; q[#q + 1] = e.j end end end
  return md, #q end
-- «вскрывается»: сколько ходов до первого состояния, где тело снова не висит ни на чём (сорвался с приманки на дно)
local function toFloor(j) local seen, q, h = { [j] = 0 }, { j }, 1
  while h <= #q do local u = q[h]; h = h + 1; if has(anch(sts[u])) == "" then return seen[u] end
    for _, e in ipairs(succ[u]) do if not seen[e.j] then seen[e.j] = seen[u] + 1; q[#q + 1] = e.j end end end end
local rows = {}
for i = 1, #sts do if live[i] then for _, e in ipairs(succ[i]) do
  local a0, a1 = anch(sts[i]), anch(sts[e.j])
  for _, tag in ipairs({ "under", "under2" }) do if a1[tag] and not a0[tag] then
    local md, sz = bfsMax(e.j)
    rows[#rows + 1] = string.format("%-6s %s | из [%s] %s | %s | в %s | глубина %d, карман %d, до «лежит на дне» мин. %s",
      tag, e.fall and "падение" or "шаг   ", has(a0), onPath[i] and ("НА ПУТИ шаг " .. onPath[i]) or ("вне пути, от пути " .. tostring(dp[i])),
      P.region and "" or "", dead[e.j] and "мёртвое" or "ЖИВОЕ", md, sz, tostring(toFloor(e.j)))
  end end
end end end
table.sort(rows); for _, r in ipairs(rows) do print(r) end
-- состояния «висит на приманке» всего
local cu = { under = 0, under2 = 0 }; for i = 1, #sts do local a = anch(sts[i]); for t in pairs(cu) do if a[t] then cu[t] = cu[t] + 1 end end end
print("состояний, прикрученных к under: " .. cu.under .. ", к under2: " .. cu.under2)
-- с каких шагов пути (по живым, ≤ 3 хода вбок) достижимы входы в приманки; сколько ходов вбок
local function from(tag)
  local res = {}
  for k, s in ipairs(path) do
    local seen, q, h = { [s] = 0 }, { s }, 1; local best
    while h <= #q do local u = q[h]; h = h + 1
      for _, e in ipairs(succ[u]) do
        local a0, a1 = anch(sts[u]), anch(sts[e.j])
        if a1[tag] and not a0[tag] and (not best or seen[u] < best) then best = seen[u] end
        if live[e.j] and not seen[e.j] and seen[u] < 3 and not onPath[e.j] then seen[e.j] = seen[u] + 1; q[#q + 1] = e.j end
      end end
    if best then res[#res + 1] = (k - 1) .. ":+" .. best end
  end
  return table.concat(res, " ")
end
print("вход в under с шагов пути (шаг:+ходов вбок): " .. from("under"))
print("вход в under2 с шагов пути (шаг:+ходов вбок): " .. from("under2"))
