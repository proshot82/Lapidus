-- build/l3c/cfg.lua файл.lua — разрез графа по конфигурациям деталей (без решений):
-- для каждой конфигурации фаянса: живых / мёртвых состояний Лапидуса, помечено ли видимым проигрышем.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local rn = arg[2] and arg[2]:match("rule=(%w+)")
if rn then def.visibleLoss = dofile("build/l3c/vis.lua").make(def.step, false, ({ narrow = {}, d = { d = true }, e = { e = true }, wide = { d = true, e = true } })[rn]) end
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local function cfg(st)
  local t = {}
  for q, p in ipairs(lvl.pieces) do if p.movable then
    if st.pos[q] == 0 then t[#t+1] = "--" else local x, y = R.xy(lvl, st.pos[q]); t[#t+1] = string.format("%d%d", x, y) end
  end end
  table.sort(t)
  return table.concat(t, " ")
end
local C = {}
for i = 1, G.n do if G.flag[i] ~= 2 then
  local st = R.decode(lvl, G.keys[i]); local k = cfg(st)
  local c = C[k] or { live = 0, dead = 0, vis = 0 }; C[k] = c
  if good[i] == 1 then c.live = c.live + 1 else c.dead = c.dead + 1; if def.visibleLoss and def.visibleLoss(lvl, st) then c.vis = c.vis + 1 end end
end end
local L = {}
for k, c in pairs(C) do L[#L+1] = { k, c } end
table.sort(L, function(a, b) return (a[2].live + a[2].dead) > (b[2].live + b[2].dead) end)
for _, e in ipairs(L) do
  local c = e[2]
  print(string.format("%-10s живых %5d мёртвых %5d%s", e[1], c.live, c.dead, def.visibleLoss and string.format(" (видимых %d)", c.vis) or ""))
end
SV.freeGraph(G)
