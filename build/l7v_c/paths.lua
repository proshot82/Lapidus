-- build/l7v_c/paths.lua [фильтр] — все кратчайшие решения (в графе с фильтром teeNoRow7 / lapNoFoot или без):
-- печатает только последовательность конфигураций деталей («события») каждого решения и метрику прогулки,
-- без ходов Лапидуса.
local M = dofile("build/l7v_c/lib.lua")
local R = M.R
local def, lvl = M.load()
local k = {}
for q, p in ipairs(lvl.pieces) do if p.tag then k[p.tag] = q end; if p.source then k.src = q end end
local sx, sy = R.xy(lvl, lvl.pieces[k.src].start)
local function row(c) local _, y = R.xy(lvl, c); return y end
local function col(c) return c ~= 0 and (R.xy(lvl, c)) == sx end
local filters = {
  teeNoRow7 = function(lvl, st, ns) local c = ns.pos[k.tee]; return not (c ~= 0 and row(c) == 7) end,
  lapNoFoot = function(lvl, st, ns)
    if ns.fixed[k.nip] then return true end
    for _, c in ipairs(ns.body) do if col(c) and row(c) >= sy - lvl.R then return false end end
    return true end,
}
local G = assert(M.SV.explore(lvl, 3000000, arg[1] and filters[arg[1]]))
local opt = G.depth[G.firstWin]
local ES, E = G.eStart.p, G.edges.p
-- DAG кратчайших: рёбра depth+1; идём назад от всех побед глубины opt
local wins = {}
for i = 1, G.n do if G.flag[i] == 1 and G.depth[i] == opt then wins[#wins + 1] = i end end
local sols = {}
local function dfs(i, acc)
  acc[#acc + 1] = i
  if G.depth[i] == opt then
    if G.flag[i] == 1 then local t = {}; for j = 1, #acc do t[j] = acc[j] end; sols[#sols + 1] = t end
  else
    for e = ES[i - 1], ES[i] - 1 do local j = E[e]; if G.depth[j] == G.depth[i] + 1 then dfs(j, acc) end end
  end
  acc[#acc] = nil
end
-- ограничим DFS: только состояния, из которых достижима победа глубины opt (иначе перебор велик)
local onOpt = {}
for _, w in ipairs(wins) do onOpt[w] = true end
for d = opt - 1, 0, -1 do
  for i = 1, G.n do
    if G.depth[i] == d and G.flag[i] == 0 then
      for e = ES[i - 1], ES[i] - 1 do local j = E[e]; if onOpt[j] and G.depth[j] == d + 1 then onOpt[i] = true break end end
    end
  end
end
local function dfs2(i, acc)
  acc[#acc + 1] = i
  if G.flag[i] == 1 then local t = {}; for j = 1, #acc do t[j] = acc[j] end; sols[#sols + 1] = t
  else for e = ES[i - 1], ES[i] - 1 do local j = E[e]; if onOpt[j] and G.depth[j] == G.depth[i] + 1 then dfs2(j, acc) end end end
  acc[#acc] = nil
end
dfs2(1, {})
print(string.format("%s: оптимум %d, кратчайших решений %d", arg[1] or "без фильтра", opt, #sols))
local seen = {}
for _, sol in ipairs(sols) do
  local ev, streak, maxStreak, last = {}, 0, 0, nil
  for idx, id in ipairs(sol) do
    local st = R.decode(lvl, G.keys[id])
    local c = M.cfg(lvl, st)
    if c ~= last then if last then ev[#ev + 1] = string.format("%d:%s", idx - 1, c) end; last = c; if idx > 1 then streak = 0 end
    else streak = streak + 1; if streak > maxStreak then maxStreak = streak end end
  end
  local key = table.concat(ev, " | ")
  if not seen[key] then seen[key] = 0 end
  seen[key] = seen[key] + 1
  seen[key .. "#walk"] = maxStreak
end
for key, cnt in pairs(seen) do
  if not key:find("#walk") then print(string.format("  ×%d, прогулка max %d: %s", cnt, seen[key .. "#walk"], key)) end
end
M.SV.freeGraph(G)
