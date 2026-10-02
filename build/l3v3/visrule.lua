-- build/l3v3/visrule.lua [файл] — правило visibleLoss уровня: сколько помечает, что сверх линейки, ложные срабатывания,
-- согласованность с washOk и с «нужным» мылом линейки.
local L = dofile("build/l3v3/lib.lua")
local path = arg[1] or "levels/03.lua"
local ctx = L.load(path, 4)
local G, lvl, def = ctx.G, ctx.lvl, ctx.def
-- линейка без правила уровня
local def2 = L.SV.deepcopy(def); def2.visibleLoss = nil
L.V.POCKET = 4
local VL0 = L.V.compute(lvl, G, def2, ctx.good)
local both, ruleOnly, rulerOnly, none, liveRule, winRule = 0, 0, 0, 0, 0, 0
local ruleOnlyC, rulerOnlyC, ruleC = {}, {}, {}
local n = 0
for i = 1, G.n do
  if G.flag[i] ~= 2 then
    n = n + 1
    local st = ctx.sts[i]
    local r = def.visibleLoss(lvl, st) and true or false
    local u = VL0.newbie[i] and true or false
    local k = L.cfg(ctx, st)
    if r then ruleC[k] = (ruleC[k] or 0) + 1 end
    if r and u then both = both + 1 elseif r then ruleOnly = ruleOnly + 1; ruleOnlyC[k] = (ruleOnlyC[k] or 0) + 1
    elseif u then rulerOnly = rulerOnly + 1; rulerOnlyC[k] = (rulerOnlyC[k] or 0) + 1 else none = none + 1 end
    if r and ctx.good[i] == 1 then liveRule = liveRule + 1 end
    if r and G.flag[i] == 1 then winRule = winRule + 1 end
  end
end
print(string.format("несмытых состояний %d: правило уровня И линейка %d | только правило %d | только линейка %d | никто %d", n, both, ruleOnly, rulerOnly, none))
print(string.format("правило уровня на живых: %d, на победе: %d (должно быть 0 и 0)", liveRule, winRule))
local function dump(t, title)
  print(title)
  local l = {}
  for k, v in pairs(t) do l[#l + 1] = { k, v } end
  table.sort(l, function(a, b) return a[2] > b[2] end)
  for _, e in ipairs(l) do print(string.format("   %4d  %s", e[2], e[1])) end
end
dump(ruleC, "что помечает правило уровня (по классам):")
dump(ruleOnlyC, "только правило уровня (сверх линейки):")
dump(rulerOnlyC, "только линейка (правило уровня молчит):")
-- «нужное» мыло по линейке
print("нужные детали по линейке: " .. table.concat(ctx.VL.needed, ","))
-- бывает ли нижнее мыло (деталь 4) где-то, кроме пола (5,7)/(4,7) и слива?
local where = {}
for i = 1, G.n do if G.flag[i] ~= 2 then local c = ctx.sts[i].pos[4]; local k = c == 0 and "смыто" or string.format("(%d,%d)", L.xy(ctx, c)); where[k] = (where[k] or 0) + 1 end end
dump(where, "где бывает нижнее мыло (деталь 4):")
local where3 = {}
for i = 1, G.n do if G.flag[i] ~= 2 then local c = ctx.sts[i].pos[3]; local k = c == 0 and "смыто" or string.format("(%d,%d)", L.xy(ctx, c)); where3[k] = (where3[k] or 0) + 1 end end
dump(where3, "где бывает верхнее мыло (деталь 3):")
L.free(ctx)
