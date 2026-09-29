-- build/l7v_d/hint.lua [файл уровня] — подсказка №1 и первые развилки, без ходов.
-- 1) Исходы первых ходов со старта (какая деталь куда уходит), статус и размер/глубина скрытой области.
-- 2) «Пробка»: в каких живых/скрытых состояниях Лапидус стоит в столбе фонтана неприкрученным (то, о чём подсказка),
--    и как эти состояния распределены по конфигурациям деталей: используется ли пробка в живых состояниях и в скрытых.
-- 3) Ошибка «пробка не тем концом / не в тот момент»: состояния, где Лапидус коркует столб, а заглушка уже наверху.
local L = dofile("build/l7v_d/lib.lua")
local ctx = L.load(arg[1])
local G, R, lvl = ctx.G, ctx.R, ctx.lvl
local n = G.n
local qe, qp = ctx.q.elbow, ctx.q.plug

local function hiddenRegion(j)
  local d, q, h, maxd, cnt = { [j] = 0 }, { j }, 1, 0, 1
  while h <= #q do
    local u = q[h]; h = h + 1
    for _, v in ipairs(L.edges(ctx, u)) do
      if L.status(ctx, v) == "hid" and d[v] == nil then d[v] = d[u] + 1; cnt = cnt + 1; if d[v] > maxd then maxd = d[v] end; q[#q + 1] = v end
    end
  end
  return cnt, maxd
end
-- через сколько ходов из j неизбежно станет видимо (максимальная глубина скрытой области = сколько можно блуждать)
print("старт: " .. L.cfg(ctx, ctx.sts[1]))
for _, j in ipairs(L.edges(ctx, 1)) do
  local s = L.status(ctx, j)
  local line = string.format("  первый ход → %-4s %s", s, L.cfg(ctx, ctx.sts[j]))
  if s == "hid" then local cnt, maxd = hiddenRegion(j); line = line .. string.format("   скрытая область %d состояний, блуждать до %d ходов", cnt, maxd) end
  print(line)
end
-- вторые ходы из живых первых
print("\nвторой ход (из живых состояний после первого):")
local seen2 = {}
for _, j in ipairs(L.edges(ctx, 1)) do
  if L.status(ctx, j) == "live" then
    for _, k in ipairs(L.edges(ctx, j)) do
      local s = L.status(ctx, k)
      local key = s .. " " .. L.cfg(ctx, ctx.sts[k])
      if not seen2[key] then seen2[key] = true
        local line = "  " .. key
        if s == "hid" then local cnt, maxd = hiddenRegion(k); line = line .. string.format("   скрытая область %d, блуждать до %d", cnt, maxd) end
        print(line)
      end
    end
  end
end

-- пробка: тело Лапидуса в клетках столба фонтана (струя вверх от тройника), Лапидус не прикручен
local function corkInfo(st)
  local jets = R.jets(lvl, st)
  local col = {}
  for _, j in ipairs(jets) do if j.dir == R.UP and not j.lapidus then for _, c in ipairs(j.cells) do col[c] = true end end end
  local h, f = L.anchors(ctx, st)
  local inCol = 0
  for _, c in ipairs(st.body) do if col[c] then inCol = inCol + 1 end end
  return inCol, (h or f) ~= nil
end
print("\n«пробка» (неприкрученный Лапидус в столбе фонтана) по конфигурациям деталей:")
local tab = {}
for i = 1, n do
  if G.flag[i] ~= 2 and G.flag[i] ~= 1 then
    local st = ctx.sts[i]
    local inCol, anch = corkInfo(st)
    if inCol > 0 and not anch then
      local k = L.cfg(ctx, st)
      local s = L.status(ctx, i)
      tab[k] = tab[k] or { live = 0, hid = 0, vis = 0 }
      tab[k][s] = tab[k][s] + 1
    end
  end
end
local l = {}
for k, v in pairs(tab) do l[#l + 1] = { k, v } end
table.sort(l, function(a, b) return (a[2].live + a[2].hid) > (b[2].live + b[2].hid) end)
for idx, e in ipairs(l) do if idx <= 25 then print(string.format("  живых %4d скрытых %4d видимых %4d  %s", e[2].live, e[2].hid, e[2].vis, e[1])) end end
L.free(ctx)
