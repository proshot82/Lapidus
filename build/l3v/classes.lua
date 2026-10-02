-- build/l3v/classes.lua [файл уровня] — классы скрытых и видимых тупиков по конфигурации мыла (без ходов).
-- Для каждого класса скрытых: сколько состояний, куда ещё может уйти каждое мыло в будущем (замыкание вперёд),
-- и есть ли ложные срабатывания разметки на живых состояниях.
local L = dofile("build/l3v/lib.lua")
local ctx = L.load(arg[1])
local G, R, lvl = ctx.G, ctx.R, ctx.lvl
local n = G.n
local cnt = { live = 0, vis = 0, hid = 0, wash = 0, win = 0 }
local byClass = { hid = {}, vis = {}, live = {} }
local classStates = {}
for i = 1, n do
  local s = L.status(ctx, i)
  cnt[s] = cnt[s] + 1
  if s == "hid" or s == "vis" or s == "live" then
    local k = L.cfg(ctx, ctx.sts[i])
    byClass[s][k] = (byClass[s][k] or 0) + 1
    classStates[s] = classStates[s] or {}
    classStates[s][k] = classStates[s][k] or {}
    table.insert(classStates[s][k], i)
  end
end
print(string.format("состояний %d: живых %d, видимых %d, скрытых %d, смыт %d, побед %d", n, cnt.live, cnt.vis, cnt.hid, cnt.wash, cnt.win))
print(string.format("скрытых %.1f %% от (скрытых+живых)", 100 * cnt.hid / (cnt.hid + cnt.live)))

-- ложные срабатывания: живые состояния, помеченные разметкой
local fp, fpRule = 0, 0
for i = 1, n do
  if ctx.good[i] == 1 and G.flag[i] ~= 2 then
    if ctx.VL.newbie[i] then fp = fp + 1 end
    if ctx.def.visibleLoss(lvl, ctx.sts[i]) then fpRule = fpRule + 1 end
  end
end
print(string.format("живых, помеченных видимо проигранными: общая линейка %d, правило уровня %d", fp, fpRule))
print("причины видимых по линейке: washed=" .. ctx.VL.counts.washed .. " frozen=" .. ctx.VL.counts.frozen .. " levelRule=" .. ctx.VL.counts.levelRule)

-- замыкание вперёд от набора состояний: куда ещё уходит каждое мыло
local function future(ids)
  local seen, q = {}, {}
  for _, i in ipairs(ids) do seen[i] = true; q[#q + 1] = i end
  local h = 1
  local posSet = {}
  for _, sq in ipairs(ctx.soaps) do posSet[sq] = {} end
  while h <= #q do
    local u = q[h]; h = h + 1
    if G.flag[u] ~= 2 then
      local st = ctx.sts[u]
      for _, sq in ipairs(ctx.soaps) do
        local c = st.pos[sq]
        local key = (c == 0) and "смыто" or string.format("(%d,%d)", R.xy(lvl, c))
        posSet[sq][key] = true
      end
    end
    for _, v in ipairs(L.edges(ctx, u)) do if not seen[v] then seen[v] = true; q[#q + 1] = v end end
  end
  local out = {}
  for _, sq in ipairs(ctx.soaps) do
    local l = {}
    for k in pairs(posSet[sq]) do l[#l + 1] = k end
    table.sort(l)
    out[#out + 1] = "мыло" .. sq .. "→{" .. table.concat(l, ",") .. "}"
  end
  return table.concat(out, " ")
end

local function dump(kind, title)
  print("\n== " .. title .. " ==")
  local l = {}
  for k, v in pairs(byClass[kind]) do l[#l + 1] = { k, v } end
  table.sort(l, function(a, b) return a[2] > b[2] end)
  for _, e in ipairs(l) do
    local extra = ""
    if kind == "hid" then extra = "   будущее: " .. future(classStates[kind][e[1]]) end
    print(string.format("  %4d  %s%s", e[2], e[1], extra))
  end
end
dump("hid", "СКРЫТЫЕ тупики по конфигурации мыла (верхнее, нижнее; /под чем лежит)")
dump("vis", "ВИДИМЫЕ потери по конфигурации мыла")

-- входы в скрытую область из живых: по переходу конфигураций (число рёбер и число живых состояний-источников)
print("\n== входы живое → скрытое (рёбра по переходу конфигураций) ==")
local ent, srcs = {}, {}
local pathSet = {}
for _, i in ipairs(L.path(ctx)) do pathSet[i] = true end
local fromPath = {}
for i = 1, n do
  if ctx.good[i] == 1 and G.flag[i] ~= 2 then
    for _, j in ipairs(L.edges(ctx, i)) do
      if L.status(ctx, j) == "hid" then
        local k = L.cfg(ctx, ctx.sts[i]) .. "  →  " .. L.cfg(ctx, ctx.sts[j])
        ent[k] = (ent[k] or 0) + 1
        srcs[i] = true
        if pathSet[i] then fromPath[k] = (fromPath[k] or 0) + 1 end
      end
    end
  end
end
local l = {}
for k, v in pairs(ent) do l[#l + 1] = { k, v } end
table.sort(l, function(a, b) return a[2] > b[2] end)
local ns = 0
for _ in pairs(srcs) do ns = ns + 1 end
print("живых состояний с выходом в скрытое: " .. ns .. " из " .. cnt.live)
for _, e in ipairs(l) do print(string.format("  %4d  %s%s", e[2], e[1], fromPath[e[1]] and ("   [с кратчайшего пути: " .. fromPath[e[1]] .. "]") or "")) end

-- живые классы (для понимания, что обезьяна считает «безопасным»)
print("\n== ЖИВЫЕ по конфигурации мыла ==")
local l2 = {}
for k, v in pairs(byClass.live) do l2[#l2 + 1] = { k, v } end
table.sort(l2, function(a, b) return a[2] > b[2] end)
for _, e in ipairs(l2) do print(string.format("  %4d  %s", e[2], e[1])) end
L.free(ctx)
