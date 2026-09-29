-- build/l2v3/wall2.lua — k6: почему клетка с тем же числом ходов не мёртвая (решение то же? какие абляции ожили?);
-- цифра скрытых после замуровки мёртвого с сохранением приманок; дно ям. Только метрики, без ходов.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local file = arg[1] or "build/l2e/k6.lua"
local base = dofile(file)
local function metrics(def)
  local lvl = R.compile(def)
  local G = SV.explore(lvl, 3000000)
  if not G.firstWin then local n = G.n; SV.freeGraph(G); return { solvable = false, n = n } end
  local good = SV.goodSet(G)
  local live, hid, free = 0, 0, 0
  for i = 1, G.n do if G.flag[i] ~= 2 then
    if good[i] == 1 then live = live + 1 else
      local st = R.decode(lvl, G.keys[i])
      if not (def.visibleLoss and def.visibleLoss(lvl, st)) then hid = hid + 1
        local piece = R.occupancy(st)
        if not (R.endScrew(lvl, st, piece, "head") or R.endScrew(lvl, st, piece, "heel")) then free = free + 1 end
      end end end end
  local path, x = {}, G.firstWin
  while x ~= 1 do table.insert(path, 1, G.pmove[x]); x = G.parent[x] end
  local r = { solvable = true, n = G.n, opt = G.depth[G.firstWin], live = live, hid = hid, free = free, pct = 100 * hid / math.max(1, hid + live), moves = path, lvl = lvl }
  SV.freeGraph(G); require("ffi").C.free(good)
  return r
end
local function replay(lvl, moves)
  local s = R.newState(lvl)
  for _, m in ipairs(moves) do s = R.move(lvl, s, R.MOVES[m].which, R.MOVES[m].dir); if not s or s.dead then return false end end
  return R.isWin(lvl, s)
end
local function abl(def)
  local t = {}
  for _, a in ipairs(SV.ablations(def, { cap = 3000000 })) do if a.solvable ~= false then t[#t + 1] = a.name end end
  return t
end
local function wallCell(d, x, y) d.grid[y] = d.grid[y]:sub(1, x - 1) .. "#" .. d.grid[y]:sub(x + 1) end
local B = metrics(base)
print(string.format("БАЗА: ходов %d, живых %d, скрытых %d (из них свободно лежащих, ни на чём не висит: %d) = %.1f %%",
  B.opt, B.live, B.hid, B.free, B.pct))
print(string.format("  без свободно лежащих в ямах: %d / %d = %.1f %%", B.hid - B.free, B.hid - B.free + B.live,
  100 * (B.hid - B.free) / (B.hid - B.free + B.live)))
print("клетки, где ходов столько же, но не мёртвое:")
for _, c in ipairs({ { 3, 6 }, { 3, 7 }, { 4, 7 }, { 3, 8 }, { 4, 8 }, { 4, 9 }, { 6, 9 }, { 7, 9 }, { 8, 8 }, { 6, 8 }, { 7, 8 }, { 6, 7 }, { 7, 7 }, { 8, 7 } }) do
  local d = SV.deepcopy(base); wallCell(d, c[1], c[2])
  local m = metrics(d)
  local a = abl(d)
  print(string.format("  (%d,%d): ходов %d, то же решение ход-в-ход: %s; ожили абляции: [%s]; скрытых %.1f %%",
    c[1], c[2], m.opt, tostring(replay(m.lvl, B.moves)), table.concat(a, "; "), m.pct))
end
-- мёртвое с сохранением приманок
local d = SV.deepcopy(base)
for _, c in ipairs({ { 6, 2 }, { 6, 3 }, { 3, 9 }, { 8, 9 } }) do wallCell(d, c[1], c[2]) end
local m = metrics(d)
print(string.format("замурованы 4 мёртвые клетки, приманки оставлены: ходов %d, то же решение: %s, абляции ожили: [%s]; живых %d, скрытых %d (свободно лежащих %d) = %.1f %%; без свободно лежащих %.1f %%",
  m.opt, tostring(replay(m.lvl, B.moves)), table.concat(abl(d), "; "), m.live, m.hid, m.free, m.pct, 100 * (m.hid - m.free) / (m.hid - m.free + m.live)))
-- только одна из приманок
for _, tag in ipairs({ "under", "under2" }) do
  local d2 = SV.deepcopy(d)
  local keep = {}
  for _, o in ipairs(d2.objects) do if o.tag == tag then wallCell(d2, o.at[1], o.at[2]) else keep[#keep + 1] = o end end
  d2.objects = keep
  local m2 = metrics(d2)
  print(string.format("  … и без приманки %s: скрытых %d = %.1f %%", tag, m2.hid, m2.pct))
end
