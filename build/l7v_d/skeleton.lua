-- build/l7v_d/skeleton.lua [файл уровня] — скелет решений без ходов: переходы между живыми конфигурациями деталей
-- (какая деталь куда сдвигается, оставаясь в живом состоянии), порядок закрепления деталей на всех выигрышных путях,
-- число решений до длины опт+k.
local L = dofile("build/l7v_d/lib.lua")
local ctx = L.load(arg[1])
local G, R, lvl = ctx.G, ctx.R, ctx.lvl
local n = G.n
local qe, qp = ctx.q.elbow, ctx.q.plug
local function pcfg(st) return "угольник" .. L.pieceDesc(ctx, st, qe) .. " заглушка" .. L.pieceDesc(ctx, st, qp) end
local trans = {}
for i = 1, n do
  if G.flag[i] ~= 2 and ctx.good[i] == 1 and G.flag[i] ~= 1 then
    local a = pcfg(ctx.sts[i])
    for _, j in ipairs(L.edges(ctx, i)) do
      if G.flag[j] ~= 2 and ctx.good[j] == 1 then
        local b = pcfg(ctx.sts[j])
        if a ~= b then local k = a .. "  →  " .. b; trans[k] = (trans[k] or 0) + 1 end
      end
    end
  end
end
print("== живые переходы конфигураций (рёбра) ==")
local l = {}
for k, v in pairs(trans) do l[#l + 1] = { k, v } end
table.sort(l, function(a, b) return a[1] < b[1] end)
for _, e in ipairs(l) do print(string.format("  %4d  %s", e[2], e[1])) end

-- порядок закрепления: живые состояния с «угольник закреплён, заглушка нет» / «заглушка закреплена, угольник нет» / переход «ни одна → обе»
local eOnly, pOnly, both1 = 0, 0, 0
for i = 1, n do
  if G.flag[i] ~= 2 and ctx.good[i] == 1 then
    local st = ctx.sts[i]
    if st.fixed[qe] and not st.fixed[qp] then eOnly = eOnly + 1 end
    if st.fixed[qp] and not st.fixed[qe] then pOnly = pOnly + 1 end
    if not st.fixed[qe] and not st.fixed[qp] then
      for _, j in ipairs(L.edges(ctx, i)) do if G.flag[j] ~= 2 and ctx.sts[j].fixed[qe] and ctx.sts[j].fixed[qp] then both1 = both1 + 1 end end
    end
  end
end
print(string.format("\nживых с «только угольник закреплён»: %d; «только заглушка закреплена»: %d; рёбер «ни одна → обе разом» из живых: %d", eOnly, pOnly, both1))

-- число решений длины опт..опт+4 (число путей от старта в победу ровно такой длины; учитываются все пути, не только простые)
local opt = G.depth[G.firstWin]
local maxK = 4
-- DP по длине: cnt[len][state]; состояния победы терминальны
local cur = { [1] = 1 }
local wins = {}
for len = 1, opt + maxK do
  local nxt = {}
  for i, c in pairs(cur) do
    if G.flag[i] ~= 1 then
      for _, j in ipairs(L.edges(ctx, i)) do if G.flag[j] ~= 2 then nxt[j] = (nxt[j] or 0) + c end end
    end
  end
  local w = 0
  for i, c in pairs(nxt) do if G.flag[i] == 1 then w = w + c end end
  wins[len] = w
  cur = nxt
end
local parts = {}
for len = opt, opt + maxK do parts[#parts + 1] = string.format("%d ходов: %d", len, wins[len] or 0) end
print("число выигрышных путей по длине: " .. table.concat(parts, "; "))
L.free(ctx)
