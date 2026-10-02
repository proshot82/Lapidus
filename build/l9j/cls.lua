-- build/l9j/cls.lua файл — классы конфигураций деталей: всего / живых / видимых (новичок) / скрытых
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local VL = V.compute(lvl, G, def, good)
local C = {}
for i = 1, G.n do if G.flag[i] ~= 2 then
  local s = R.decode(lvl, G.keys[i]); local t = {}
  for q, p in ipairs(lvl.pieces) do if p.movable then
    if s.pos[q] == 0 then t[#t+1] = p.tag .. "(-)" else local x, y = R.xy(lvl, s.pos[q]); t[#t+1] = string.format("%s(%d,%d)%s", p.tag, x, y, s.fixed[q] and "F" or "") end end end
  local k = table.concat(t, " ")
  local c = C[k] or { 0, 0, 0, 0 }; C[k] = c
  c[1] = c[1] + 1
  if good[i] == 1 then c[2] = c[2] + 1 elseif VL.newbie[i] then c[3] = c[3] + 1 else c[4] = c[4] + 1 end
end end
local l = {}
for k, c in pairs(C) do l[#l+1] = k end
table.sort(l, function(a, b) return C[a][1] > C[b][1] end)
print("конфигурация: всего живых видимых скрытых")
for i = 1, math.min(tonumber(arg[2] or 40), #l) do local c = C[l[i]]; print(string.format("%-40s %6d %6d %6d %6d", l[i], c[1], c[2], c[3], c[4])) end
SV.freeGraph(G)
