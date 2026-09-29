-- build/l4v2/livepos.lua — где бывает ниппель (и муфта) в живых состояниях; для проверки, что класс L — «нечем поднять».
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1] or "build/l4d/k40.lua")
if arg[2] then def.length = { 2, tonumber(arg[2]) } end
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local qn, qc
for q, p in ipairs(lvl.pieces) do if p.what == "nipple" then qn = q elseif p.what == "coupling" then qc = q end end
local agg, aggAll = {}, {}
for i = 1, G.n do if G.flag[i] ~= 2 then local s = R.decode(lvl, G.keys[i]); local x, y = R.xy(lvl, s.pos[qn])
  local k = x .. "," .. y .. (s.fixed[qn] and "F" or "")
  aggAll[k] = (aggAll[k] or 0) + 1
  if good[i] == 1 then agg[k] = (agg[k] or 0) + 1 end end end
local t = {}
for k, v in pairs(aggAll) do t[#t + 1] = string.format("%s: всего %d, живых %d", k, v, agg[k] or 0) end
table.sort(t); print(table.concat(t, "\n"))
