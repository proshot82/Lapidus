-- build/l3v/posthint.lua [файл уровня] — что остаётся от головоломки после подсказки №1.
-- Берём состояние кратчайшего пути сразу после верного выбивания подставки (нижнее мыло смыто впервые)
-- и считаем подзадачу: достижимые состояния, живые/скрытые/видимые, умная обезьяна оттуда, расстояние до победы,
-- а также самая длинная «отходная» от живых состояний с мылом уже на ступеньке (цена подъёма не тем концом).
local L = dofile("build/l3v/lib.lua")
local ctx = L.load(arg[1])
local G, R, lvl = ctx.G, ctx.R, ctx.lvl
local path = L.path(ctx)
local opt = #path - 1
local kick
for k, i in ipairs(path) do if ctx.sts[i] and ctx.sts[i].pos[4] == 0 then kick = k - 1; break end end
local s0 = path[kick + 1]
print(string.format("подставка выбита на ходу %d из %d; конфигурация после: %s", kick, opt, L.cfg(ctx, ctx.sts[s0])))

-- достижимое из s0
local seen, q, h = { [s0] = true }, { s0 }, 1
local cnt = { live = 0, vis = 0, hid = 0, wash = 0, win = 0 }
while h <= #q do
  local u = q[h]; h = h + 1
  local s = L.status(ctx, u)
  cnt[s] = cnt[s] + 1
  for _, v in ipairs(L.edges(ctx, u)) do if not seen[v] then seen[v] = true; q[#q + 1] = v end end
end
print(string.format("достижимо из этого состояния: живых %d, скрытых %d, видимых %d, смыт %d", cnt.live, cnt.hid, cnt.vis, cnt.wash))
local T = 5 * (opt - kick)
local ok, live, dead = L.monkey(ctx, s0, T)
print(string.format("умная обезьяна из этого состояния за %d ходов: выигрыш %.3f %% (за 1000 ходов: %.2f %%), жива %.1f %%, в тупиках %.1f %%",
  T, 100 * ok, 100 * (1 - (1 - ok) ^ (1000 / T)), 100 * live, 100 * dead))
local ok2 = L.monkey(ctx, s0, 1000)
print(string.format("умная обезьяна из этого состояния за 1000 ходов без перезапуска: %.2f %%", 100 * ok2))

-- расстояние до победы по живым состояниям (обратный BFS от победы)
local rev = {}
for i = 1, G.n do
  if G.flag[i] ~= 2 then for _, j in ipairs(L.edges(ctx, i)) do rev[j] = rev[j] or {}; table.insert(rev[j], i) end end
end
local dist = { [G.firstWin] = 0 }
local qq, hh = { G.firstWin }, 1
while hh <= #qq do
  local u = qq[hh]; hh = hh + 1
  for _, p in ipairs(rev[u] or {}) do if dist[p] == nil then dist[p] = dist[u] + 1; qq[#qq + 1] = p end end
end
-- живые с мылом на ступеньке: разброс расстояний до победы
local step = (7 - 1) * lvl.W + 7
local hist, maxd, n = {}, 0, 0
for i = 1, G.n do
  if ctx.good[i] == 1 and G.flag[i] ~= 2 and G.flag[i] ~= 1 and ctx.sts[i].pos[3] == step then
    local d = dist[i]; n = n + 1
    hist[d] = (hist[d] or 0) + 1
    if d > maxd then maxd = d end
  end
end
local parts = {}
for d = 0, maxd do if hist[d] then parts[#parts + 1] = d .. ":" .. hist[d] end end
print(string.format("живых состояний с мылом на ступеньке: %d; расстояние до победы (ходов:состояний): %s", n, table.concat(parts, " ")))
print(string.format("минимум от ступеньки до победы на кратчайшем пути: %d ходов; худшее живое положение с мылом на ступеньке: %d ходов до победы", opt - 21 >= 0 and (function() for k, i in ipairs(path) do if ctx.sts[i] and ctx.sts[i].pos[3] == step then return opt - (k - 1) end end end)() or -1, maxd))

-- узкие места: живые состояния, через которые проходит любая победа (как в review.lua), с конфигурацией
local function reachableWithout(ban)
  local sn, qu, hq = { [1] = true }, { 1 }, 1
  while hq <= #qu do
    local u = qu[hq]; hq = hq + 1
    if G.flag[u] == 1 then return true end
    for _, v in ipairs(L.edges(ctx, u)) do if v ~= ban and not sn[v] and G.flag[v] ~= 2 then sn[v] = true; qu[#qu + 1] = v end end
  end
  return false
end
for k = 2, #path - 1 do
  if not reachableWithout(path[k]) then
    print(string.format("узкое место после хода %d: %s (длина Лапидуса %d)", k - 1, L.cfg(ctx, ctx.sts[path[k]]), #ctx.sts[path[k]].body))
  end
end
L.free(ctx)
