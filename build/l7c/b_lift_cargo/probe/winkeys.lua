package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
for i = 1, G.n do
  if G.flag[i] == 1 then
    local st = R.decode(lvl, G.keys[i])
    local t = {}
    for q, p in ipairs(lvl.pieces) do t[#t+1] = string.format("%s:asm%d%s", p.tag or p.kind, st.asm[q], st.fixed[q] and "F" or "") end
    print(G.depth[i], table.concat(t, " "))
  end
end
SV.freeGraph(G)
