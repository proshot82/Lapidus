-- build/l9a/width.lua файл.lua — ширина коридора кратчайших решений по глубинам: сколько разных состояний на каждой
-- глубине лежат на кратчайших путях, и чем они отличаются (конфигурация деталей, клетки тела). Ходы не печатаются.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local ST = require("solver.strict")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = ST.graph(def, 3000000)
assert(G and G.opt, "нерешаем")
-- состояния на кратчайших путях: dist[i] + расстояние до победы == opt
local n = G.n
local rev = {}
for i = 1, n do for _, j in ipairs(G.succ[i] or {}) do rev[j] = rev[j] or {}; table.insert(rev[j], i) end end
local dw = {}
local q, h = {}, 1
for i = 1, n do if G.win[i] and G.dist[i] == G.opt then dw[i] = 0; q[#q+1] = i end end
while h <= #q do local j = q[h]; h = h + 1; for _, i in ipairs(rev[j] or {}) do if dw[i] == nil then dw[i] = dw[j] + 1; q[#q+1] = i end end end
-- восстановим состояния повторным обходом (ST.graph не хранит их): пере-BFS с ключами
local s0 = R.newState(lvl)
local ids, sts, order = { [R.key(s0)] = 1 }, { [1] = s0 }, { 1 }
local hh = 1
while hh <= #order do
  local i = order[hh]; hh = hh + 1
  local s = sts[i]
  if not s.dead and not R.isWin(lvl, s) then
    for m = 1, 8 do
      local mv = R.MOVES[m]
      local ns = R.move(lvl, s, mv.which, mv.dir)
      if ns then local k = R.key(ns); if not ids[k] then ids[k] = #order + 1; sts[#order + 1] = ns; order[#order + 1] = #order + 1 end end
    end
  end
end
local function cfg(s)
  local t = {}
  for qq, p in ipairs(lvl.pieces) do if p.movable then
    if s.pos[qq] == 0 then t[#t+1] = p.tag .. "=смыт" else local x, y = R.xy(lvl, s.pos[qq]); t[#t+1] = string.format("%s(%d,%d)%s", p.tag, x, y, s.fixed[qq] and "F" or "") end end end
  local b = {}
  for _, c in ipairs(s.body) do local x, y = R.xy(lvl, c); b[#b+1] = x .. "," .. y end
  return table.concat(t, " ") .. " | тело " .. table.concat(b, " ")
end
local byDepth = {}
for i = 1, n do if dw[i] and G.dist[i] + dw[i] == G.opt then byDepth[G.dist[i]] = byDepth[G.dist[i]] or {}; table.insert(byDepth[G.dist[i]], i) end end
for d = 0, G.opt do
  local l = byDepth[d] or {}
  local line = string.format("глубина %2d: %d", d, #l)
  if #l > 1 then
    for _, i in ipairs(l) do line = line .. "\n    " .. cfg(sts[i]) end
  end
  print(line)
end
