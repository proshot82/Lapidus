-- build/l4d/width.lua файл.lua — ширина коридора кратчайших решений по глубине (сколько состояний на кратчайших путях
-- на каждом ходу) и конфигурации деталей на этих глубинах. Только в терминал.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local ST = require("solver.strict")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = ST.graph(def, 3000000)
local cnt = { [1] = 1 }
for i = 1, G.n do
  local c = cnt[i]
  if c and not G.win[i] and not G.dead[i] then
    for _, j in ipairs(G.succ[i]) do if G.dist[j] == G.dist[i] + 1 then cnt[j] = (cnt[j] or 0) + c end end
  end
end
local on = {}
for i = 1, G.n do if G.win[i] and G.dist[i] == G.opt then on[i] = true end end
for i = G.n, 1, -1 do
  if not on[i] and not G.win[i] and not G.dead[i] and G.dist[i] < G.opt then
    for _, j in ipairs(G.succ[i]) do if on[j] and G.dist[j] == G.dist[i] + 1 then on[i] = true; break end end
  end
end
local width = {}
for i = 1, G.n do if on[i] then width[G.dist[i]] = (width[G.dist[i]] or 0) + 1 end end
local line = {}
for d = 0, G.opt do line[#line + 1] = d .. ":" .. (width[d] or 0) end
print(table.concat(line, " "))
-- подробности по глубинам из аргументов (только в терминал): детали и тело Лапидуса
local G2 = ST.graph(def, 3000000) -- повторный обход ради состояний (ST.graph их не хранит)
local R2 = require("core.rules")
local s0 = R2.newState(lvl)
local ids, sts, order, dist = { [R2.key(s0)] = 1 }, { s0 }, { 1 }, { 0 }
local h = 1
while h <= #order do
  local i = order[h]; h = h + 1
  local s = sts[i]
  if not (R2.isWin(lvl, s)) and not s.dead then
    for m = 1, 8 do
      local mv = R2.MOVES[m]
      local ns = R2.move(lvl, s, mv.which, mv.dir)
      if ns then local k = R2.key(ns); if not ids[k] then local j = #dist + 1; ids[k], sts[j], dist[j] = j, ns, dist[i] + 1; order[#order + 1] = j end end
    end
  end
end
for a = 2, #arg do
  local d = tonumber(arg[a])
  for i = 1, G.n do
    if on[i] and G.dist[i] == d then
      local s = sts[i]
      local t = {}
      for q, p in ipairs(lvl.pieces) do if p.movable then local x, y = R.xy(lvl, s.pos[q]); t[#t+1] = string.format("%s(%d,%d)%s", p.tag, x, y, s.fixed[q] and "F" or "") end end
      local b = {}
      for _, c in ipairs(s.body) do local x, y = R.xy(lvl, c); b[#b+1] = string.format("(%d,%d)", x, y) end
      print(string.format("  глубина %d: %s  тело ноги→голова %s", d, table.concat(t, " "), table.concat(b, "")))
    end
  end
end
