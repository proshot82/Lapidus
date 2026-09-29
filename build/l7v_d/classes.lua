-- build/l7v_d/classes.lua [файл уровня] — классы скрытых и видимых тупиков по конфигурации деталей (без ходов).
-- Для каждого класса скрытых: сколько состояний и куда ещё может уйти каждая деталь в будущем (замыкание вперёд);
-- ложные срабатывания разметки на живых состояниях; причины видимых по общей линейке.
local L = dofile("build/l7v_d/lib.lua")
local ctx = L.load(arg[1])
local G, R, lvl = ctx.G, ctx.R, ctx.lvl
local n = G.n
local cnt = { live = 0, vis = 0, hid = 0, wash = 0, win = 0 }
local byClass = { hid = {}, vis = {}, live = {} }
local classStates = { hid = {}, vis = {}, live = {} }
for i = 1, n do
  local s = L.status(ctx, i)
  cnt[s] = cnt[s] + 1
  if byClass[s] then
    local k = L.cfg(ctx, ctx.sts[i])
    byClass[s][k] = (byClass[s][k] or 0) + 1
    classStates[s][k] = classStates[s][k] or {}
    table.insert(classStates[s][k], i)
  end
end
print(string.format("состояний %d: живых %d, видимых %d, скрытых %d, смыт %d, побед %d", n, cnt.live, cnt.vis, cnt.hid, cnt.wash, cnt.win))
print(string.format("скрытых %.1f %% от (скрытых+живых)", 100 * cnt.hid / (cnt.hid + cnt.live)))
local fp, fpRule = 0, 0
for i = 1, n do
  if ctx.good[i] == 1 and G.flag[i] ~= 2 then
    if ctx.VL.newbie[i] then fp = fp + 1 end
    if ctx.def.visibleLoss and ctx.def.visibleLoss(lvl, ctx.sts[i]) then fpRule = fpRule + 1 end
  end
end
print(string.format("живых, помеченных видимо проигранными: общая линейка %d, правило уровня %d", fp, fpRule))
local c = ctx.VL.counts
print(string.format("причины видимых по линейке: washed=%d frozen=%d levelRule=%d (omni-goal сверх того: %d)", c.washed, c.frozen, c.levelRule, c.goal))

local function future(ids)
  local seen = L.forward(ctx, ids)
  local posSet = { elbow = {}, plug = {} }
  local anch = {}
  for u in pairs(seen) do
    if G.flag[u] ~= 2 then
      local st = ctx.sts[u]
      for _, nm in ipairs({ "elbow", "plug" }) do posSet[nm][L.pieceDesc(ctx, st, ctx.q[nm])] = true end
    end
  end
  local out = {}
  for _, nm in ipairs({ "elbow", "plug" }) do
    local l = {}
    for k in pairs(posSet[nm]) do l[#l + 1] = k end
    table.sort(l)
    out[#out + 1] = nm .. "→{" .. table.concat(l, ",") .. "}"
  end
  return table.concat(out, " ")
end

local function dump(kind, title, withFuture, limit)
  print("\n== " .. title .. " ==")
  local l = {}
  for k, v in pairs(byClass[kind]) do l[#l + 1] = { k, v } end
  table.sort(l, function(a, b) return a[2] > b[2] end)
  for idx, e in ipairs(l) do
    if limit and idx > limit then print(string.format("  ... ещё %d классов", #l - limit)) break end
    local extra = ""
    if withFuture then extra = "   будущее: " .. future(classStates[kind][e[1]]) end
    print(string.format("  %4d  %s%s", e[2], e[1], extra))
  end
end
dump("hid", "СКРЫТЫЕ тупики по конфигурации деталей", true)
dump("vis", "ВИДИМЫЕ потери по конфигурации деталей", false, 40)
dump("live", "ЖИВЫЕ по конфигурации деталей", false, 40)
L.free(ctx)
