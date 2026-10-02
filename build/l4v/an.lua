-- build/l4v/an.lua — слепая проверка кв. 4 (k29): правила visibleLoss, классы скрытых тупиков, «что если видимо».
-- luajit build/l4v/an.lua файл.lua [POCKET]   (печатает только метрики, без ходов)
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local file = arg[1] or "build/l4v/k29_ruleid.lua"
if arg[2] then V.POCKET = tonumber(arg[2]) end
local def = dofile(file)
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local VL = V.compute(lvl, G, def, good)
local def0 = {}
for k, v in pairs(def) do def0[k] = v end
def0.visibleLoss = nil
local VL0 = V.compute(lvl, G, def0, good)
local qc, qn, S
for q, p in ipairs(lvl.pieces) do
  if p.what == "coupling" then qc = q elseif p.what == "nipple" then qn = q end
  if p.source then S = p.start end
end
local B = lvl.nb[S][1]; local T = lvl.nb[B][1]
local base = V.measure(G, good, VL.newbie)
print(string.format("POCKET=%d  ходов %d | живых %d видимых %d скрытых %d | СКРЫТЫХ %.1f %% | обезьяна %.3f %% | глубина %d [%s]",
  V.POCKET, base.opt, base.live, base.vis, base.hid, base.hiddenPct, base.smart, base.maxDeep, base.deepList))
local ex = V.measure(G, good, VL.expert)
print(string.format("знаток: скрытых %.1f %% | обезьяна %.3f %% | глубина %d", ex.hiddenPct, ex.smart, ex.maxDeep))
-- 1) правила уровня
local rs = {}
local sts = VL.states
for i = 1, G.n do
  if G.flag[i] ~= 2 then
    local r = def.visibleLoss(lvl, sts[i])
    if r then
      local t = rs[r] or { fire = 0, live = 0, only = 0 }; rs[r] = t
      t.fire = t.fire + 1
      if good[i] == 1 then t.live = t.live + 1 end
      if not VL0.newbie[i] then t.only = t.only + 1 end
    end
  end
end
print("правило уровня: срабатываний / из них живых / добавлено сверх общей линейки")
for _, r in ipairs({ "wash", "r1", "r2", "r3", "r4" }) do
  local t = rs[r] or { fire = 0, live = 0, only = 0 }
  print(string.format("  %-5s %6d %6d %6d", r, t.fire, t.live, t.only))
end
local m0 = V.measure(G, good, VL0.newbie)
print(string.format("без правил уровня (только общая линейка): скрытых %.1f %% | обезьяна %.3f %% | глубина %d", m0.hiddenPct, m0.smart, m0.maxDeep))
-- 2) классы скрытых
local classes = {
  { "К1 муфта прикручена не на стояке", function(st) return st.fixed[qc] and st.pos[qc] ~= B end },
  { "К2 ниппель прикручен не в шахте", function(st) return st.fixed[qn] and st.pos[qn] ~= T end },
  { "К3 пара свинчена заранее (свободна)", function(st) return not st.fixed[qc] and not st.fixed[qn] and st.asm[qc] == st.asm[qn] end },
  { "К4 муфта на стояке, ниппель свободен", function(st) return st.fixed[qc] and st.pos[qc] == B and not st.fixed[qn] end },
  { "К5 обе свободны, порознь", function(st) return not st.fixed[qc] and not st.fixed[qn] and st.asm[qc] ~= st.asm[qn] end },
  { "К6 обе на месте", function(st) return st.fixed[qc] and st.pos[qc] == B and st.fixed[qn] and st.pos[qn] == T end },
}
local hc = {}
local hiddenTotal = 0
for i = 1, G.n do
  if G.flag[i] ~= 2 and good[i] ~= 1 and not VL.newbie[i] then
    hiddenTotal = hiddenTotal + 1
    for k, c in ipairs(classes) do if c[2](sts[i]) then hc[k] = (hc[k] or 0) + 1 end end
  end
end
print("классы скрытых (всего " .. hiddenTotal .. "):")
local function withExtra(pred)
  local L = {}
  for i = 1, G.n do if G.flag[i] ~= 2 then L[i] = VL.newbie[i] or (good[i] ~= 1 and pred(sts[i])) end end
  return V.measure(G, good, L)
end
for k, c in ipairs(classes) do
  local m = withExtra(c[2])
  print(string.format("  %-40s скрытых %5d | если видимо: скрытых %.1f %%, обезьяна %.3f %%, глубина %d [%s]",
    c[1], hc[k] or 0, m.hiddenPct, m.smart, m.maxDeep, m.deepList))
end
local both = withExtra(function(st) return classes[1][2](st) or classes[2][2](st) end)
print(string.format("  К1+К2 видимы: скрытых %.1f %%, обезьяна %.3f %%, глубина %d [%s]", both.hiddenPct, both.smart, both.maxDeep, both.deepList))
local three = withExtra(function(st) return classes[1][2](st) or classes[2][2](st) or classes[3][2](st) end)
print(string.format("  К1+К2+К3 видимы: скрытых %.1f %%, обезьяна %.3f %%, глубина %d [%s]", three.hiddenPct, three.smart, three.maxDeep, three.deepList))
_G.AN = { G = G, good = good, VL = VL, sts = sts, lvl = lvl, qc = qc, qn = qn, B = B, T = T, withExtra = withExtra, def = def }
if arg[3] == "census" then
  local agg = {}
  for i = 1, G.n do
    if G.flag[i] ~= 2 and good[i] ~= 1 and not VL.newbie[i] then
      local st = sts[i]
      local t = {}
      for _, q in ipairs({ qc, qn }) do local x, y = R.xy(lvl, st.pos[q]); t[#t + 1] = string.format("%s(%d,%d)%s", lvl.pieces[q].tag, x, y, st.fixed[q] and "F" or "") end
      local key = table.concat(t, " ") .. ((st.asm[qc] == st.asm[qn] and not st.fixed[qc]) and " пара" or "")
      agg[key] = (agg[key] or 0) + 1
    end
  end
  local l = {}
  for k, v in pairs(agg) do l[#l + 1] = { k, v } end
  table.sort(l, function(a, b) return a[2] > b[2] end)
  for i = 1, math.min(40, #l) do print(string.format("    %5d  %s", l[i][2], l[i][1])) end
end
