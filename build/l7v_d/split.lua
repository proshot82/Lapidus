-- build/l7v_d/split.lua [файл уровня] — разбор отдельных классов без ходов:
--  1) «обе детали на месте»: где Лапидус в живых и в скрытых состояниях (минимальный/максимальный x, якорь, длина);
--  2) «запечатанная деталь»: нужная незакреплённая деталь не на месте, все её будущие положения — только текущее
--     или такие, где она уже никогда не сдвинется (обобщение «замёрзла» на один толчок вперёд); сколько скрытых ловит;
--  3) карман слева (2,6),(3,6),(3,5) и «отгороженные» детали у (4,5)/(4,6) при Лапидусе вне кармана.
local L = dofile("build/l7v_d/lib.lua")
local ctx = L.load(arg[1])
local G, R, lvl = ctx.G, ctx.R, ctx.lvl
local n = G.n
local qe, qp = ctx.q.elbow, ctx.q.plug
local win = ctx.win

local function lapBox(st)
  local minx, maxx, miny, maxy = 99, 0, 99, 0
  for _, c in ipairs(st.body) do local x, y = R.xy(lvl, c); minx = math.min(minx, x); maxx = math.max(maxx, x); miny = math.min(miny, y); maxy = math.max(maxy, y) end
  return minx, maxx, miny, maxy
end

print("== 1) обе детали закреплены на месте: положение Лапидуса ==")
local tab = {}
for i = 1, n do
  if G.flag[i] ~= 2 and G.flag[i] ~= 1 then
    local st = ctx.sts[i]
    if st.fixed[qe] and st.fixed[qp] then
      local minx, maxx, miny, maxy = lapBox(st)
      local h, f = L.anchors(ctx, st)
      local k = string.format("x %d..%d y %d..%d len %d %s", minx, maxx, miny, maxy, #st.body, (f and "якорь-ноги" or (h and "якорь-голова" or "")))
      local s = L.status(ctx, i)
      tab[k] = tab[k] or { live = 0, hid = 0, vis = 0 }
      tab[k][s] = tab[k][s] + 1
    end
  end
end
local l = {}
for k, v in pairs(tab) do l[#l + 1] = { k, v } end
table.sort(l, function(a, b) return a[1] < b[1] end)
local sumLiveLeft, sumHidLeft, sumLiveRight, sumHidRight = 0, 0, 0, 0
for _, e in ipairs(l) do
  print(string.format("  %-40s живых %4d  скрытых %4d  видимых %4d", e[1], e[2].live, e[2].hid, e[2].vis))
  local minx = tonumber(e[1]:match("x (%d+)"))
  if minx <= 6 then sumLiveLeft = sumLiveLeft + e[2].live; sumHidLeft = sumHidLeft + e[2].hid else sumLiveRight = sumLiveRight + e[2].live; sumHidRight = sumHidRight + e[2].hid end
end
print(string.format("  итого: Лапидус хоть одной клеткой при x<=6: живых %d скрытых %d; целиком при x>=7: живых %d скрытых %d", sumLiveLeft, sumHidLeft, sumLiveRight, sumHidRight))

print("\n== 2) «запечатанная» деталь (все будущие положения — текущее или замёрзшие) ==")
-- canMove по графу (как в vislib): состояние, из которого деталь q ещё когда-нибудь сдвинется
local function reverseAdj()
  local rev = {}
  for i = 1, n do if G.flag[i] ~= 2 then for _, j in ipairs(L.edges(ctx, i)) do if G.flag[j] ~= 2 then rev[j] = rev[j] or {}; table.insert(rev[j], i) end end end end
  return rev
end
local rev = reverseAdj()
local function backClosure(seeds)
  local mark, q = {}, {}
  for i in pairs(seeds) do mark[i] = true; q[#q + 1] = i end
  local h = 1
  while h <= #q do local j = q[h]; h = h + 1; for _, i in ipairs(rev[j] or {}) do if not mark[i] then mark[i] = true; q[#q + 1] = i end end end
  return mark
end
local canMove = {}
for _, q in ipairs({ qe, qp }) do
  local mv = {}
  for i = 1, n do if G.flag[i] ~= 2 then local pi = ctx.sts[i].pos[q]; for _, j in ipairs(L.edges(ctx, i)) do if G.flag[j] ~= 2 and ctx.sts[j].pos[q] ~= pi then mv[i] = true; break end end end end
  canMove[q] = backClosure(mv)
end
-- forward closure per state is expensive; instead: sealed(i,q) = not canGoal-like: compute set F(i) of states reachable; too heavy per state.
-- Обходимся так: деталь «запечатана» в состоянии i, если ни одно достижимое из i состояние не имеет деталь q в положении,
-- отличном от текущего, где она ещё может сдвинуться (canMove). Считаем через обратное замыкание от «хороших положений»:
-- seeds = состояния j, где деталь q не закреплена, canMove[q][j], и существует ребро k→j с pos[k][q] ~= pos[j][q] (деталь только что сдвинулась и ещё подвижна),
-- либо деталь q в j закреплена на своём месте (win.pos). Тогда sealed(i) = деталь не на месте, не закреплена, и i не в backClosure(seeds).
local sealed = {}
for _, q in ipairs({ qe, qp }) do
  local seeds = {}
  for i = 1, n do
    if G.flag[i] ~= 2 then
      local pi = ctx.sts[i].pos[q]
      for _, j in ipairs(L.edges(ctx, i)) do
        if G.flag[j] ~= 2 then
          local sj = ctx.sts[j]
          if sj.pos[q] ~= pi and ((not sj.fixed[q] and canMove[q][j]) or (sj.fixed[q] and sj.pos[q] == win.pos[q])) then seeds[j] = true end
        end
      end
    end
  end
  local ok = backClosure(seeds)
  sealed[q] = {}
  for i = 1, n do
    if G.flag[i] ~= 2 then
      local st = ctx.sts[i]
      if not st.fixed[q] and st.pos[q] ~= win.pos[q] and not ok[i] then sealed[q][i] = true end
    end
  end
end
local cnt = { hid = {}, vis = {}, live = {} }
local byCls = {}
for i = 1, n do
  if G.flag[i] ~= 2 and G.flag[i] ~= 1 then
    local s = L.status(ctx, i)
    local which = (sealed[qe][i] and "угольник" or "") .. (sealed[qp][i] and "заглушка" or "")
    if which ~= "" then
      cnt[s][which] = (cnt[s][which] or 0) + 1
      if s == "hid" then local k = L.cfg(ctx, ctx.sts[i]); byCls[k] = (byCls[k] or 0) + 1 end
    end
  end
end
for _, s in ipairs({ "live", "hid", "vis" }) do
  local parts = {}
  for k, v in pairs(cnt[s]) do parts[#parts + 1] = k .. "=" .. v end
  print(string.format("  %-5s запечатано: %s", s, table.concat(parts, ", ")))
end
print("  скрытые, которые ловит «запечатана», по конфигурациям:")
local l2 = {}
for k, v in pairs(byCls) do l2[#l2 + 1] = { k, v } end
table.sort(l2, function(a, b) return a[2] > b[2] end)
for _, e in ipairs(l2) do print(string.format("    %4d  %s", e[2], e[1])) end

print("\n== 3) карман слева и отгороженные детали ==")
local pocket = { [L.idx(ctx, 2, 6)] = true, [L.idx(ctx, 3, 6)] = true, [L.idx(ctx, 3, 5)] = true }
local wallCells = { [L.idx(ctx, 4, 5)] = true, [L.idx(ctx, 4, 6)] = true }
local c3 = { A = { live = 0, hid = 0, vis = 0 }, B = { live = 0, hid = 0, vis = 0 }, AorB = { live = 0, hid = 0, vis = 0 } }
for i = 1, n do
  if G.flag[i] ~= 2 and G.flag[i] ~= 1 then
    local st = ctx.sts[i]
    local s = L.status(ctx, i)
    local A, B = false, false
    for _, q in ipairs({ qe, qp }) do if not st.fixed[q] and pocket[st.pos[q]] then A = true end end
    local lapIn = false
    for _, c in ipairs(st.body) do if pocket[c] then lapIn = true end end
    if not lapIn then for _, q in ipairs({ qe, qp }) do if not st.fixed[q] and wallCells[st.pos[q]] then B = true end end end
    if A then c3.A[s] = c3.A[s] + 1 end
    if B then c3.B[s] = c3.B[s] + 1 end
    if A or B then c3.AorB[s] = c3.AorB[s] + 1 end
  end
end
for _, k in ipairs({ "A", "B", "AorB" }) do print(string.format("  %-5s живых %d скрытых %d видимых %d", k, c3[k].live, c3[k].hid, c3[k].vis)) end
L.free(ctx)
