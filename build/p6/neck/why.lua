-- build/p6/neck/why.lua файл.lua ходы... — почему состояние после ходов помечено видимым проигрышем (диагностика)
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local VL = V.compute(lvl, G, def, good)
local st = R.newState(lvl)
local map = { h = "head", f = "heel" }
local dm = { u = 1, r = 2, d = 3, l = 4 }
for i = 2, #arg do st = assert(R.move(lvl, st, map[arg[i]:sub(1,1)], dm[arg[i]:sub(2,2)])) end
local id = G.index[R.key(st)]
print("good", good[id], "newbie", VL.newbie[id], "expert", VL.expert[id])
for _, q in ipairs(VL.needed) do
  print(lvl.pieces[q].tag, "pos", st.pos[q], "goal", VL.win.pos[q], "fixed", st.fixed[q], "canMove", VL.canMove[q][id], "sealed", VL.sealedBy[q][id])
end
