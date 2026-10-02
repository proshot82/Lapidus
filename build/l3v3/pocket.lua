-- build/l3v3/pocket.lua [файл] — доля скрытых при кармане 3/4/5/6 и классы скрытых/видимых по конфигурации мыла.
local L = dofile("build/l3v3/lib.lua")
local path = arg[1] or "levels/03.lua"
for _, P in ipairs({ 3, 4, 5, 6 }) do
  local ctx = L.load(path, P)
  local G = ctx.G
  local cnt = { live = 0, vis = 0, hid = 0, wash = 0, win = 0 }
  local hidC, visC = {}, {}
  for i = 1, G.n do
    local s = L.status(ctx, i)
    cnt[s] = cnt[s] + 1
    if s == "hid" then local k = L.cfg(ctx, ctx.sts[i]); hidC[k] = (hidC[k] or 0) + 1 end
    if s == "vis" then local k = L.cfg(ctx, ctx.sts[i]); visC[k] = (visC[k] or 0) + 1 end
  end
  local c = ctx.VL.counts
  print(string.format("КАРМАН %d: живых %d, скрытых %d, видимых %d (линейка: смыто %d, заморожено/запечатано %d, правило уровня %d) → скрытых %.1f %%",
    P, cnt.live, cnt.hid, cnt.vis, c.washed, c.frozen, c.levelRule, 100 * cnt.hid / (cnt.hid + cnt.live)))
  local l = {}
  for k, v in pairs(hidC) do l[#l + 1] = { k, v } end
  table.sort(l, function(a, b) return a[2] > b[2] end)
  for _, e in ipairs(l) do print(string.format("   скрытые %4d  %s", e[2], e[1])) end
  if P == 4 then
    local l2 = {}
    for k, v in pairs(visC) do l2[#l2 + 1] = { k, v } end
    table.sort(l2, function(a, b) return a[2] > b[2] end)
    for _, e in ipairs(l2) do print(string.format("   видимые %4d  %s", e[2], e[1])) end
  end
  L.free(ctx)
end
