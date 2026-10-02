-- какие правила широкого видимого проигрыша срабатывают на живых состояниях (печатает конфигурации, без путей)
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = dofile("build/l7c/b_lift_cargo/vis.lua")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local wide, mine = V.make("wide"), V.make("mine")
local n = 0
for i = 1, G.n do
  if G.flag[i] == 0 and good[i] == 1 then
    local st = R.decode(lvl, G.keys[i])
    if wide(lvl, st) and not mine(lvl, st) then
      n = n + 1
      if n <= 6 then
        local t = {}
        for q, p in ipairs(lvl.pieces) do if p.movable then local x, y = R.xy(lvl, st.pos[q]); t[#t+1] = string.format("%s(%d,%d)%s", p.tag, x, y, st.fixed[q] and "F" or "") end end
        local b = {}
        for _, c in ipairs(st.body) do local x, y = R.xy(lvl, c); b[#b+1] = x .. "," .. y end
        print(table.concat(t, " ") .. " | тело " .. table.concat(b, " "))
      end
    end
  end
end
print("всего", n)
SV.freeGraph(G)
