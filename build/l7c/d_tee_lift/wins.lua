-- wins.lua файл.lua — все выигрышные конечные конфигурации (детали и тело Лапидуса) — вывод инструмента.
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
    for q, p in ipairs(lvl.pieces) do if p.movable then local x, y = R.xy(lvl, st.pos[q]); t[#t+1] = (p.tag or p.what) .. "(" .. x .. "," .. y .. ")" .. (st.fixed[q] and "F" or "") .. "a" .. st.asm[q] end end
    local b = {}
    for _, c in ipairs(st.body) do local x, y = R.xy(lvl, c); b[#b+1] = x .. "," .. y end
    print("#" .. i .. " глубина " .. G.depth[i] .. ": " .. table.concat(t, " ") .. " | тело(ноги→голова) " .. table.concat(b, " "))
  end
end
SV.freeGraph(G)
