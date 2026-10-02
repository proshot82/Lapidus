-- build/l8a/anch.lua файл.lua — в каких достижимых состояниях Лапидус прикручен и к чему (подсчёт; только терминал)
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
if arg[2] ~= "keep" then local o2 = {} for _, o in ipairs(def.objects) do if not (o.kind == "fitting" or o.kind == "porcelain") then o2[#o2+1] = o end end def.objects = o2 end
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local c = {}
for i = 1, G.n do if G.flag[i] ~= 2 then
  local st = R.decode(lvl, G.keys[i]); local w = R.water(lvl, st)
  local k = (w.headQ and ("голова→" .. w.headQ) or "") .. (w.heelQ and (" ноги→" .. w.heelQ) or "")
  if k == "" then k = "не прикручен" end
  c[k] = (c[k] or 0) + 1
end end
for k, v in pairs(c) do print(v, k) end
for q, p in ipairs(lvl.pieces) do local x, y = R.xy(lvl, p.start); print(q, p.kind, x, y) end
SV.freeGraph(G)
