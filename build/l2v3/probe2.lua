-- build/l2v3/probe2.lua — k6 (по образцу l2v2): когда вскрывается ошибка у каждой двери; обезьяна из разных точек; бассейн дымохода.
-- Только метрики, без ходов.
package.path = "./?.lua;" .. package.path
arg = { arg[1] or "build/l2e/k6.lua" }
local real = print; print = function() end
local P = dofile("build/l2v3/probe.lua")
print = real
local R = require("core.rules")
local def = dofile(arg[1]); local lvl = R.compile(def)
local sts, succ, live, dead, path = P.sts, P.succ, P.live, P.dead, P.path
local n = #sts
local W = lvl.W
local function xy(c) return (c - 1) % W + 1, math.floor((c - 1) / W) + 1 end
local win = {}; for i = 1, n do win[i] = not sts[i].dead and R.isWin(lvl, sts[i]) end
-- близость к цели ступени: колодец (карман справа) — клетка лаза (5,5); шахта (карман слева) — клетка у якоря (3,4)
local function tgt(i) local mx = 0; for _, c in ipairs(sts[i].body) do local x = xy(c); if x > mx then mx = x end end
  if mx >= 6 then return 5, 5 end; return 3, 4 end
local function near(i, tx, ty) if not tx then tx, ty = tgt(i) end
  local b = 99; for _, c in ipairs(sts[i].body) do local x, y = xy(c); local d = math.abs(x - tx) + math.abs(y - ty); if d < b then b = d end end; return b end
local function bfs(j, only)
  local seen, q, h = { [j] = 0 }, { j }, 1
  while h <= #q do local u = q[h]; h = h + 1
    for _, e in ipairs(succ[u]) do if not seen[e.j] and (not only or only[e.j]) then seen[e.j] = seen[u] + 1; q[#q + 1] = e.j end end end
  return q, seen
end
print("двери с пути: вход → лучшее приближение к цели ступени (лаз (5,5) / якорь (3,4)) внутри кармана и через сколько ходов")
for k = 1, #path - 1 do
  for _, e in ipairs(succ[path[k]]) do if dead[e.j] then
    local q, seen = bfs(e.j, dead); local best, bd = 99, 0; local tx, ty = tgt(e.j)
    for _, u in ipairs(q) do local d = near(u, tx, ty); if d < best or (d == best and seen[u] < bd) then best, bd = d, seen[u] end end
    local hint = def.hintError(lvl, sts[path[k]], sts[e.j])
    print(string.format("  шаг %2d: сразу после входа до цели = %d; лучшее в кармане = %d через %d ходов%s", k - 1, near(e.j, tx, ty), best, bd, hint and "  [ошибка подсказки]" or ""))
  end end
end
-- случайный игрок (все ходы равновероятны) из разных точек пути
local function monkey(start, T)
  local p, ok = { [start] = 1 }, 0
  for _ = 1, T do local np = {}
    for i, pr in pairs(p) do local c = succ[i]
      if #c == 0 then np[i] = (np[i] or 0) + pr else for _, e in ipairs(c) do local sh = pr / #c
        if win[e.j] then ok = ok + sh else np[e.j] = (np[e.j] or 0) + sh end end end end
    p = np end
  local d = 0; for i, pr in pairs(p) do if dead[i] then d = d + pr end end
  return ok, d
end
for _, k in ipairs({ 0, 3, 8, 10, 12, 16 }) do
  local ok, d = monkey(path[k + 1], 80)
  print(string.format("случайный из шага %2d пути, 80 ходов: выигрыш %.3f %%, в кармане %.1f %%", k, 100 * ok, 100 * d))
end
-- выбор на пути: ходы, сокращающие расстояние до цели (сколько «продвигающих» на шаге)
local dg = {}; do local q, h = {}, 1; for i = 1, n do if win[i] then dg[i] = 0; q[#q + 1] = i end end
  local rev = {}; for i = 1, n do for _, e in ipairs(succ[i]) do rev[e.j] = rev[e.j] or {}; table.insert(rev[e.j], i) end end
  while h <= #q do local j = q[h]; h = h + 1; for _, i in ipairs(rev[j] or {}) do if not dg[i] then dg[i] = dg[j] + 1; q[#q + 1] = i end end end end
local line = {}
for k = 1, #path - 1 do local s = path[k]; local prog, side, back, door = 0, 0, 0, 0
  for _, e in ipairs(succ[s]) do if dead[e.j] then door = door + 1 elseif dg[e.j] and dg[e.j] < dg[s] then prog = prog + 1 elseif dg[e.j] and dg[e.j] == dg[s] then side = side + 1 else back = back + 1 end end
  line[#line + 1] = string.format("%d:п%d/б%d/н%d/д%d", k - 1, prog, side, back, door) end
print("по шагам: п — продвигают, б — вбок, н — назад (живые), д — двери")
print("  " .. table.concat(line, " "))
