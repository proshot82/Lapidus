-- build/l3v2/rule.lua — правило уровня visibleLoss: сколько срабатывает, сколько добавляет сверх общей линейки,
-- помечает ли живые; классы срабатываний по конфигурации мыла.
local L = dofile("build/l3v/lib.lua")
local path = arg[1] or "build/l3d/s8.lua"
local ctx = L.load(path)
local V = ctx.V
local def2 = dofile(path); def2.visibleLoss = nil
local VL0 = V.compute(ctx.lvl, ctx.G, def2, ctx.good)
local fire, live, extra, dup = 0, 0, 0, 0
local cls = {}
for i = 1, ctx.G.n do if ctx.G.flag[i] == 0 then
  local st = ctx.sts[i]
  if ctx.def.visibleLoss(ctx.lvl, st) then
    fire = fire + 1
    if ctx.good[i] == 1 then live = live + 1 end
    if VL0.newbie[i] then dup = dup + 1 else extra = extra + 1 end
    local k = L.cfg(ctx, st); cls[k] = (cls[k] or 0) + 1
  end end end
print(string.format("правило уровня срабатывает в %d состояниях; на живых %d; уже помечены общей линейкой %d; добавляет сверх линейки %d", fire, live, dup, extra))
for k, v in pairs(cls) do print("  " .. v .. "  " .. k) end
-- видимые по линейке, которых правило не ловит, по классам (для последовательности)
local miss = {}
for i = 1, ctx.G.n do if ctx.G.flag[i] == 0 and VL0.newbie[i] and not ctx.def.visibleLoss(ctx.lvl, ctx.sts[i]) then
  local k = L.cfg(ctx, ctx.sts[i]); miss[k] = (miss[k] or 0) + 1 end end
print("видимые по линейке, где правило молчит:")
for k, v in pairs(miss) do print("  " .. v .. "  " .. k) end
