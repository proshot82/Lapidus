-- build/l7v_d/sealed.lua [файл уровня] — обобщённое правило «запечатана» для общей линейки (предложение скептика):
-- нужная незакреплённая деталь не на месте «запечатана», если каждый её будущий сдвиг (по графу) приводит в положение,
-- где она уже замёрзла или снова запечатана (наименьшая неподвижная точка). «Замёрзла» — как в tools/vislib.lua.
-- Печатает, какие классы скрытых состояний это правило добавляет к разметке новичка, и ворота с ним.
local L = dofile("build/l7v_d/lib.lua")
local V = require("tools.vislib")
local ctx = L.load(arg[1])
local G, R, lvl = ctx.G, ctx.R, ctx.lvl
local n = G.n
local win = ctx.win
local rev = {}
for i = 1, n do if G.flag[i] ~= 2 then for _, j in ipairs(L.edges(ctx, i)) do if G.flag[j] ~= 2 then rev[j] = rev[j] or {}; table.insert(rev[j], i) end end end end
local function backClosure(seeds)
  local mark, q = {}, {}
  for i in pairs(seeds) do mark[i] = true; q[#q + 1] = i end
  local h = 1
  while h <= #q do local j = q[h]; h = h + 1; for _, i in ipairs(rev[j] or {}) do if not mark[i] then mark[i] = true; q[#q + 1] = i end end end
  return mark
end
local sealedAny = {}
for _, q in ipairs(ctx.VL.needed) do
  local mv = {}
  for i = 1, n do if G.flag[i] ~= 2 then local pi = ctx.sts[i].pos[q]; for _, j in ipairs(L.edges(ctx, i)) do if G.flag[j] ~= 2 and ctx.sts[j].pos[q] ~= pi then mv[i] = true; break end end end end
  local canMove = backClosure(mv)
  local S = {}
  for i = 1, n do if G.flag[i] ~= 2 then local st = ctx.sts[i]
    if st.pos[q] ~= 0 and not st.fixed[q] and st.pos[q] ~= win.pos[q] and not canMove[i] then S[i] = true end
    if st.pos[q] ~= 0 and st.fixed[q] and st.pos[q] ~= win.pos[q] then S[i] = true end
  end end
  local rounds = 0
  while true do
    rounds = rounds + 1
    local bad = {}
    for u = 1, n do
      if G.flag[u] ~= 2 then
        local pu = ctx.sts[u].pos[q]
        for _, v in ipairs(L.edges(ctx, u)) do
          if G.flag[v] ~= 2 and ctx.sts[v].pos[q] ~= pu and not S[v] then bad[u] = true; break end
        end
      end
    end
    local notSealed = backClosure(bad)
    local added = 0
    for i = 1, n do
      if G.flag[i] ~= 2 and not S[i] then
        local st = ctx.sts[i]
        if st.pos[q] ~= 0 and not st.fixed[q] and st.pos[q] ~= win.pos[q] and not notSealed[i] then S[i] = true; added = added + 1 end
      end
    end
    if added == 0 then break end
  end
  for i in pairs(S) do sealedAny[i] = true end
  print(string.format("деталь %s: раундов %d", lvl.pieces[q].what or q, rounds))
end
-- что добавляет к разметке новичка
local byCls, addLive, addHid = {}, 0, 0
local lost = {}
for i = 1, n do
  if G.flag[i] ~= 2 then
    lost[i] = ctx.VL.newbie[i] or sealedAny[i] or false
    if sealedAny[i] and not ctx.VL.newbie[i] then
      if ctx.good[i] == 1 then addLive = addLive + 1 else addHid = addHid + 1; local k = L.cfg(ctx, ctx.sts[i]); byCls[k] = (byCls[k] or 0) + 1 end
    end
  end
end
print(string.format("«запечатана» добавляет к разметке новичка: живых %d (должно быть 0), скрытых %d", addLive, addHid))
local l = {}
for k, v in pairs(byCls) do l[#l + 1] = { k, v } end
table.sort(l, function(a, b) return a[2] > b[2] end)
for _, e in ipairs(l) do print(string.format("  %4d  %s", e[2], e[1])) end
local M = V.measure(G, ctx.good, lost)
print(string.format("ворота с разметкой новичок+запечатана: СКРЫТЫХ %.0f %% | УМНАЯ ОБЕЗЬЯНА %.2f %% | ГЛУБИНА %d у пути [%s]", M.hiddenPct, M.smart, M.maxDeep, M.deepList))
-- живые состояния с якорем ног в тройнике / голове в угольнике
local anchTee, anchBath, anchElb = 0, 0, 0
for i = 1, n do if G.flag[i] ~= 2 and ctx.good[i] == 1 then
  local h, f = L.anchors(ctx, ctx.sts[i])
  if f and lvl.pieces[f].what == "tee" then anchTee = anchTee + 1 end
  if f and lvl.pieces[f].fixture then anchBath = anchBath + 1 end
  if h and lvl.pieces[h].what == "elbow" then anchElb = anchElb + 1 end
end end
print(string.format("живых состояний с якорем: ноги в тройнике %d, ноги в ванне %d, голова в угольнике %d", anchTee, anchBath, anchElb))
L.free(ctx)
