-- build/l7v_d/errors.lua [файл уровня] — правдоподобные ошибки и их скрытость (без ходов):
-- для каждого класса первого входа из живого в тупик (по переходу конфигураций деталей) — доля ходов, статус
-- (видимо/скрыто по разметке файла и по широкой разметке v_wide), глубина блуждания; плюс развилка на старте.
local L = dofile("build/l7v_d/lib.lua")
local ctx = L.load(arg[1])
local G, R, lvl = ctx.G, ctx.R, ctx.lvl
local n = G.n
local wide = dofile("build/l7v_d/v_wide.lua").visibleLoss
local function statusWide(i)
  if G.flag[i] == 2 then return "wash" end
  if G.flag[i] == 1 then return "win" end
  if ctx.good[i] == 1 then return "live" end
  if ctx.VL.newbie[i] or wide(lvl, ctx.sts[i]) then return "vis" end
  return "hid"
end
local function depthHidden(j, statusFn)
  local d, q, h, maxd, cnt = { [j] = 0 }, { j }, 1, 0, 1
  while h <= #q do
    local u = q[h]; h = h + 1
    for _, v in ipairs(L.edges(ctx, u)) do
      if statusFn(v) == "hid" and d[v] == nil then d[v] = d[u] + 1; cnt = cnt + 1; if d[v] > maxd then maxd = d[v] end; q[#q + 1] = v end
    end
  end
  return cnt, maxd
end
local entries = {}
for i = 1, n do
  if G.flag[i] ~= 2 and ctx.good[i] == 1 and G.flag[i] ~= 1 then
    local a = L.cfg(ctx, ctx.sts[i])
    for _, j in ipairs(L.edges(ctx, i)) do
      if G.flag[j] ~= 2 and ctx.good[j] ~= 1 then
        local b = L.cfg(ctx, ctx.sts[j])
        local k = a .. "  →  " .. b
        local e = entries[k] or { edges = 0, hidFile = 0, hidWide = 0, sample = j }
        e.edges = e.edges + 1
        if L.status(ctx, j) == "hid" then e.hidFile = e.hidFile + 1 end
        if statusWide(j) == "hid" then e.hidWide = e.hidWide + 1 end
        entries[k] = e
      end
    end
  end
end
local l = {}
for k, e in pairs(entries) do l[#l + 1] = { k, e } end
table.sort(l, function(a, b) return a[2].edges > b[2].edges end)
print("== входы живое → тупик по переходу конфигураций (рёбер; из них скрытых по файлу / по широкой разметке; блуждание) ==")
for idx, x in ipairs(l) do
  if idx > 30 then print("  ... ещё " .. (#l - 30)) break end
  local e = x[2]
  local extra = ""
  if e.hidWide > 0 then
    -- глубина скрытой области по широкой разметке от одного примера
    local j
    for i = 1, n do end
    local cnt, maxd = depthHidden(e.sample, statusWide)
    extra = string.format("   скрытая область (широкая) от примера: %d сост., блуждать до %d", cnt, maxd)
  end
  print(string.format("  %4d  скрыто файл %4d / широкая %4d  %s%s", e.edges, e.hidFile, e.hidWide, x[1], extra))
end
L.free(ctx)
