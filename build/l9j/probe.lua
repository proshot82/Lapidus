-- build/l9j/probe.lua файл.lua — что вообще достижимо: конфигурации деталей (клетка, F=окаменела) и число состояний.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
print("состояний", G.n, "решаем", G.firstWin and G.depth[G.firstWin] or "нет")
local cfgs = {}
for i = 1, G.n do
  if G.flag[i] ~= 2 then
    local st = R.decode(lvl, G.keys[i])
    local t = {}
    for q, p in ipairs(lvl.pieces) do if p.movable then
      if st.pos[q] == 0 then t[#t+1] = p.tag .. "(смыт)" else
      local x, y = R.xy(lvl, st.pos[q]); t[#t+1] = string.format("%s(%d,%d)%s", p.tag, x, y, st.fixed[q] and "F" or "") end end end
    local k = table.concat(t, " ")
    cfgs[k] = (cfgs[k] or 0) + 1
  end
end
local l = {}
for k, v in pairs(cfgs) do l[#l+1] = k end
table.sort(l)
if arg[2] == "fixed" then
  for _, k in ipairs(l) do if k:find("F") then print(cfgs[k], k) end end
else
  for _, k in ipairs(l) do print(cfgs[k], k) end
end
SV.freeGraph(G)
