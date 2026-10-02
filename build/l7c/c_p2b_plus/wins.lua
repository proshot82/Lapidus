-- wins.lua файл.lua — выигрышные состояния: позиции, закрепление и номера сборок (только вывод инструмента).
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
    for q, p in ipairs(lvl.pieces) do
      if p.movable then local x, y = R.xy(lvl, st.pos[q]); t[#t + 1] = string.format("%s(%d,%d)%s a%d", p.tag, x, y, st.fixed[q] and "F" or "", st.asm[q]) end
    end
    local b = {}
    for _, c in ipairs(st.body) do local x, y = R.xy(lvl, c); b[#b + 1] = x .. "," .. y end
    print(G.depth[i], table.concat(t, " "), "| тело " .. table.concat(b, " "))
  end
end
SV.freeGraph(G)
