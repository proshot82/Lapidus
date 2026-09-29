-- build/l3v/walks.lua [файл уровня] — прогулки и вынужденные ходы по ВСЕМ кратчайшим решениям (без порядка ходов).
-- Событие — смена положения любой детали. Прогулка — серия ходов пути подряд без событий.
-- Выбор — число живых продолжений; «без отката» — не считая ход, возвращающий в предыдущее состояние;
-- «вперёд» — продолжения, приближающие к победе (расстояние до победы уменьшается).
local L = dofile("build/l3v/lib.lua")
local ctx = L.load(arg[1])
local G, R, lvl = ctx.G, ctx.R, ctx.lvl
local opt = G.depth[G.firstWin]
-- расстояние до победы
local rev = {}
for i = 1, G.n do if G.flag[i] ~= 2 then for _, j in ipairs(L.edges(ctx, i)) do rev[j] = rev[j] or {}; table.insert(rev[j], i) end end end
local dist = { [G.firstWin] = 0 }
local qq, hh = { G.firstWin }, 1
while hh <= #qq do
  local u = qq[hh]; hh = hh + 1
  for _, p in ipairs(rev[u] or {}) do if dist[p] == nil then dist[p] = dist[u] + 1; qq[#qq + 1] = p end end
end
-- состояния на кратчайших путях
local on = { [G.firstWin] = true }
local stack = { G.firstWin }
while #stack > 0 do
  local u = table.remove(stack)
  for _, p in ipairs(rev[u] or {}) do
    if G.depth[p] == G.depth[u] - 1 and not on[p] then on[p] = true; stack[#stack + 1] = p end
  end
end
local function objs(i) local st = ctx.sts[i]; local t = {}; for q = 1, #st.pos do t[#t + 1] = st.pos[q] end; return table.concat(t, ",") end
local paths = {}
local function dfs(u, acc)
  if u == G.firstWin then local c = {}; for k, v in ipairs(acc) do c[k] = v end; paths[#paths + 1] = c; return end
  for _, v in ipairs(L.edges(ctx, u)) do
    if on[v] and G.depth[v] == G.depth[u] + 1 then acc[#acc + 1] = v; dfs(v, acc); acc[#acc] = nil end
  end
end
dfs(1, { 1 })
print(string.format("кратчайших решений %d, длина %d", #paths, opt))
for pi, path in ipairs(paths) do
  local streaks, streak, events, evAt = {}, 0, 0, {}
  local choice, noUndo, fwd = {}, {}, {}
  local maxStreak = 0
  for k = 1, #path - 1 do
    local s, nxt = path[k], path[k + 1]
    if objs(s) ~= objs(nxt) then events = events + 1; evAt[#evAt + 1] = k; if streak > 0 then streaks[#streaks + 1] = streak end; streak = 0
    else streak = streak + 1; if streak > maxStreak then maxStreak = streak end end
    local c, nu, f = 0, 0, 0
    for _, j in ipairs(L.edges(ctx, s)) do
      if G.flag[j] ~= 2 and ctx.good[j] == 1 then
        c = c + 1
        if not (k > 1 and j == path[k - 1]) then nu = nu + 1 end
        if dist[j] and dist[j] < dist[s] then f = f + 1 end
      end
    end
    choice[#choice + 1] = c; noUndo[#noUndo + 1] = nu; fwd[#fwd + 1] = f
  end
  if streak > 0 then streaks[#streaks + 1] = streak end
  print(string.format("путь %d: событий %d (на ходах %s); прогулки %s (max %d)", pi, events, table.concat(evAt, ","), table.concat(streaks, ","), maxStreak))
  print("   живых продолжений по шагам: " .. table.concat(choice, ""))
  print("   без отката:                 " .. table.concat(noUndo, ""))
  print("   вперёд (к победе):          " .. table.concat(fwd, ""))
end
-- ширина коридора кратчайших по глубине
local width = {}
for i in pairs(on) do width[G.depth[i]] = (width[G.depth[i]] or 0) + 1 end
local w = {}
for d = 0, opt do w[#w + 1] = width[d] or 0 end
print("состояний на кратчайших путях по глубине: " .. table.concat(w, ""))
L.free(ctx)
