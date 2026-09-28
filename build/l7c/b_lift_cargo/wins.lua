-- wins.lua файл.lua — различные выигрышные конфигурации (детали + клетки Лапидуса), без путей.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local seen = {}
for i = 1, G.n do
  if G.flag[i] == 1 then
    local st = R.decode(lvl, G.keys[i])
    local t = {}
    for q, p in ipairs(lvl.pieces) do if p.movable then local x, y = R.xy(lvl, st.pos[q]); t[#t+1] = string.format("%s(%d,%d)", p.tag, x, y) end end
    local b = {}
    for k, c in ipairs(st.body) do local x, y = R.xy(lvl, c); b[#b+1] = x .. "," .. y end
    local key = table.concat(t, " ")
    if not seen[key] then seen[key] = true; print(string.format("глубина %d: %s | Лапидус (ноги→голова) %s", G.depth[i], key, table.concat(b, " "))) end
  end
end
SV.freeGraph(G)
