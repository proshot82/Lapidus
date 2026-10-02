-- build/l4v2/an.lua — слепая проверка кв. 4 (k40): правила visibleLoss, перепись скрытых, классы, разметки.
-- luajit build/l4v2/an.lua [файл] [POCKET] [census]   (только метрики, без ходов)
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local file = arg[1] or "build/l4d/k40.lua"
if arg[2] and arg[2] ~= "-" then V.POCKET = tonumber(arg[2]) end
local def = dofile(file)
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local VL = V.compute(lvl, G, def, good)
local def0 = {}
for k, v in pairs(def) do def0[k] = v end
def0.visibleLoss = nil
local VL0 = V.compute(lvl, G, def0, good)
local sts = VL.states
local qc, qn, S, qw
for q, p in ipairs(lvl.pieces) do
  if p.what == "coupling" then qc = q elseif p.what == "nipple" then qn = q end
  if p.source then S = p.start end
  if p.fixture then qw = q end
end
local B = lvl.nb[S][1]; local T = lvl.nb[B][1]
local W = lvl.W
local function cell(x, y) return (y - 1) * W + x end
local function xy(c) return R.xy(lvl, c) end
local base = V.measure(G, good, VL.newbie)
print(string.format("POCKET=%d ходов %d | состояний %d | живых %d видимых %d скрытых %d | СКРЫТЫХ %.1f %% | обезьяна %.3f %% | глубина %d [%s]",
  V.POCKET, base.opt, G.n, base.live, base.vis, base.hid, base.hiddenPct, base.smart, base.maxDeep, base.deepList))
local ex = V.measure(G, good, VL.expert)
print(string.format("знаток: скрытых %.1f %% | обезьяна %.3f %% | глубина %d [%s]", ex.hiddenPct, ex.smart, ex.maxDeep, ex.deepList))
local m0 = V.measure(G, good, VL0.newbie)
print(string.format("только общая линейка: скрытых %.1f %% | глубина %d [%s]", m0.hiddenPct, m0.maxDeep, m0.deepList))
-- правила уровня по отдельности
local function ruleId(st)
  local atB, atT
  for q, p in ipairs(lvl.pieces) do if p.movable then
    if st.pos[q] == 0 then return "r0" end
    if st.pos[q] == B and st.fixed[q] then atB = q end
    if st.pos[q] == T and st.fixed[q] then atT = q end
  end end
  if atT and not atB then return "r1" end
  for q, p in ipairs(lvl.pieces) do if not p.movable then
    for d = 1, 4 do if p.ports[d] then
      local t = lvl.nb[p.start][d]
      for r = 1, #st.pos do if lvl.pieces[r].movable and st.pos[r] == t and st.fixed[r] then
        if p.kind == "stub" then return "r2" end
        if p.fixture then return "r3" end
      end end
    end end
  end end
  return nil
end
local rs = {}
for i = 1, G.n do if G.flag[i] ~= 2 then
  local r = ruleId(sts[i])
  local chk = def.visibleLoss(lvl, sts[i])
  assert((r ~= nil) == chk, "ruleId mismatch")
  if r then
    local t = rs[r] or { fire = 0, live = 0, only = 0 }; rs[r] = t
    t.fire = t.fire + 1
    if good[i] == 1 then t.live = t.live + 1 end
    if not VL0.newbie[i] then t.only = t.only + 1 end
  end
end end
print("правило: срабатываний / живых / сверх линейки")
for _, r in ipairs({ "r0", "r1", "r2", "r3" }) do local t = rs[r] or { fire = 0, live = 0, only = 0 }
  print(string.format("  %s %6d %6d %6d", r, t.fire, t.live, t.only)) end
-- классы
local function isPair(st) return st.asm[qc] == st.asm[qn] end
local function cfix(st) return st.fixed[qc] and st.pos[qc] == B end
local classes = {
  { "P  пара свинчена (свободна)", function(st) return isPair(st) and not st.fixed[qc] end },
  { "A  ниппель свободен у входа (8,6), муфта не на стояке", function(st) return not isPair(st) and not st.fixed[qn] and st.pos[qn] == cell(8, 6) and not cfix(st) end },
  { "L  ниппель свободен на полу левее машинки (x<=6, y=6)", function(st) local x, y = xy(st.pos[qn]); return not isPair(st) and not st.fixed[qn] and y == 6 and x <= 6 end },
  { "O  ниппель свободен в другом месте", function(st) local x, y = xy(st.pos[qn]); return not isPair(st) and not st.fixed[qn] and not (y == 6 and x <= 6) and st.pos[qn] ~= cell(8, 6) end },
  { "F  прочие (закреплённые)", function(st) return st.fixed[qn] or (st.fixed[qc] and isPair(st)) end },
}
local hidden, hc, hcDetail = {}, {}, {}
local htot = 0
for i = 1, G.n do
  if G.flag[i] ~= 2 and good[i] ~= 1 and not VL.newbie[i] then
    htot = htot + 1; hidden[i] = true
    local st = sts[i]
    local hit = false
    for k, c in ipairs(classes) do if c[2](st) then hc[k] = (hc[k] or 0) + 1; hit = true break end end
    if not hit then hc[99] = (hc[99] or 0) + 1 end
  end
end
local function withExtra(pred)
  local L = {}
  for i = 1, G.n do if G.flag[i] ~= 2 then L[i] = VL.newbie[i] or (good[i] ~= 1 and pred(sts[i], i)) end end
  return V.measure(G, good, L), L
end
print("классы скрытых (всего " .. htot .. "), без классов: " .. (hc[99] or 0))
for k, c in ipairs(classes) do
  local m = withExtra(c[2])
  print(string.format("  %-55s %6d (%4.1f %%) | если видимо: скрытых %.1f %%, обезьяна %.3f %%, глубина %d [%s]",
    c[1], hc[k] or 0, 100 * (hc[k] or 0) / htot, m.hiddenPct, m.smart, m.maxDeep, m.deepList))
end
local combos = { { "L", { 3 } }, { "A", { 2 } }, { "L+A", { 2, 3 } }, { "L+P", { 1, 3 } }, { "L+A+P", { 1, 2, 3 } }, { "A+P", { 1, 2 } } }
for _, cb in ipairs(combos) do
  local m = withExtra(function(st) for _, k in ipairs(cb[2]) do if classes[k][2](st) then return true end end return false end)
  print(string.format("  видимы %-6s: скрытых %.1f %% (скрытых %d, живых %d), обезьяна %.3f %%, глубина %d [%s]", cb[1], m.hiddenPct, m.hid, m.live, m.smart, m.maxDeep, m.deepList))
end
-- в классе L: сколько живых состояний с ниппелем на полу левее машинки (проверка «видим ли класс»)
local liveL, allL = 0, 0
for i = 1, G.n do if G.flag[i] ~= 2 then local st = sts[i]; local x, y = xy(st.pos[qn])
  if not st.fixed[qn] and not isPair(st) and y == 6 and x <= 6 then allL = allL + 1; if good[i] == 1 then liveL = liveL + 1 end end end end
print(string.format("ниппель свободен на полу левее машинки: всего %d, живых %d", allL, liveL))
local liveA, allA = 0, 0
for i = 1, G.n do if G.flag[i] ~= 2 then local st = sts[i]
  if not st.fixed[qn] and not isPair(st) and st.pos[qn] == cell(8, 6) and not cfix(st) then allA = allA + 1; if good[i] == 1 then liveA = liveA + 1 end end end end
print(string.format("ниппель у входа (8,6), муфта не на стояке: всего %d, живых %d", allA, liveA))
if arg[3] == "census" then
  local agg = {}
  for i in pairs(hidden) do
    local st = sts[i]; local t = {}
    for _, q in ipairs({ qc, qn }) do local x, y = xy(st.pos[q]); t[#t + 1] = string.format("%s(%d,%d)%s", lvl.pieces[q].tag, x, y, st.fixed[q] and "F" or "") end
    local key = table.concat(t, " ") .. (isPair(st) and not st.fixed[qc] and " пара" or "")
    agg[key] = (agg[key] or 0) + 1
  end
  local l = {}
  for k, v in pairs(agg) do l[#l + 1] = { k, v } end
  table.sort(l, function(a, b) return a[2] > b[2] end)
  for i = 1, math.min(40, #l) do print(string.format("    %5d  %s", l[i][2], l[i][1])) end
end
_G.AN = { G = G, good = good, VL = VL, VL0 = VL0, sts = sts, lvl = lvl, qc = qc, qn = qn, B = B, T = T, withExtra = withExtra, def = def, classes = classes, hidden = hidden, cell = cell, xy = xy, base = base }
return _G.AN
