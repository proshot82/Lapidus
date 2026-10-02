-- build/l7j/cfgs.lua файл.lua — достижимые конфигурации закреплённых деталей (для отладки раскладки)
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local V = require("tools.vislib")
local VL = G.firstWin and V.compute(lvl, G, def, good) or { newbie = {} }
local c = {}
for i = 1, G.n do if G.flag[i] ~= 2 then
  local st = R.decode(lvl, G.keys[i])
  local t = {}
  for q, p in ipairs(lvl.pieces) do if p.movable then
    if st.pos[q] == 0 then t[#t+1] = p.tag .. "смыт" elseif st.fixed[q] then local x, y = R.xy(lvl, st.pos[q]); t[#t+1] = string.format("%s(%d,%d)F", p.tag, x, y) else t[#t+1] = p.tag .. "своб" end
  end end
  local k = table.concat(t, " ")
  c[k] = c[k] or { n = 0, live = 0, d = 1e9, hid = 0 }
  if good[i] ~= 1 and not VL.newbie[i] then c[k].hid = c[k].hid + 1 end
  c[k].n = c[k].n + 1; if good[i] == 1 then c[k].live = c[k].live + 1 end
  if G.depth[i] < c[k].d then c[k].d = G.depth[i] end
end end
local ks = {} for k in pairs(c) do ks[#ks+1] = k end
table.sort(ks, function(a, b) return c[a].d < c[b].d end)
for _, k in ipairs(ks) do print(string.format("%-50s состояний %6d живых %6d скрытых %6d мин.глубина %d", k, c[k].n, c[k].live, c[k].hid, c[k].d)) end
