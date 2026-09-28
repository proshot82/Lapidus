-- quick.lua файл.lua [метка] — одной строкой: ходы, состояния, скрытых mine/wide, умная обезьяна, глубина, прогулка,
-- вынужденные, ширина коридора кратчайших (max), число выигрышных СОСТОЯНИЙ (как считает run_all). Без решений.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = dofile("build/l7c/b_lift_cargo/vis.lua")
local GT = dofile("build/l7c/b_lift_cargo/gates.lua")
local def = dofile(arg[1])
def.visibleLoss = V.make("mine")
local rm = GT.eval(def, { nostrict = true, noabl = true })
if not rm.opt then print((arg[2] or arg[1]) .. ": " .. rm.line) return end
def.visibleLoss = V.make("wide")
local rw = GT.eval(def, { nostrict = true, noabl = true })
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local nwin = 0
for i = 1, G.n do if G.flag[i] == 1 then nwin = nwin + 1 end end
local n = G.n
local E, ES = G.edges.p, G.eStart.p
local rev = {}
for i = 1, n do for e = ES[i - 1], ES[i] - 1 do local j = E[e]; local t = rev[j]; if not t then t = {}; rev[j] = t end; t[#t + 1] = i end end
local dw, q, h = {}, {}, 1
for i = 1, n do if G.flag[i] == 1 then dw[i] = 0; q[#q + 1] = i end end
while h <= #q do local u = q[h]; h = h + 1; for _, p in ipairs(rev[u] or {}) do if dw[p] == nil and G.flag[p] ~= 2 then dw[p] = dw[u] + 1; q[#q + 1] = p end end end
local opt = G.depth[G.firstWin]
local w = {}
for i = 1, n do if dw[i] and G.depth[i] + dw[i] == opt then w[G.depth[i]] = (w[G.depth[i]] or 0) + 1 end end
local maxw = 0
for d = 0, opt do if (w[d] or 0) > maxw then maxw = w[d] end end
SV.freeGraph(G)
print(string.format("%s: ходов %d | сост. %d | скрытых %.0f/%.0f %% | обезьяна %.2f %% | глубина %d/%d | прогулка %d | вынужд. %d | ширина %d | выигрышных состояний %d | событий %d",
  arg[2] or arg[1], rm.opt, rm.states, rm.hiddenPct, rw.hiddenPct, rm.smart, rm.deep, rw.deep, rm.walk, rm.forced, maxw, nwin, rm.events))
