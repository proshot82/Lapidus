-- verify_perm.lua файл.lua — скептик кв. 7 (28.09): необратимы ли признаки новых правил видимого проигрыша?
-- Для каждого признака: сколько состояний, сколько живых среди них и есть ли ход, после которого признак пропадает.
-- Только числа.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = dofile("build/l7c/a_lift_last/verify_vis.lua")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local S = {}
local function st(i) if not S[i] then S[i] = R.decode(lvl, G.keys[i]) end return S[i] end
for _, nm in ipairs({ "cornerJunk", "elbPinned", "cplInShaft" }) do
  local f = V[nm]
  local n, live, escapes, escLive = 0, 0, 0, 0
  for i = 1, G.n do
    if G.flag[i] == 0 and f(lvl, st(i)) then
      n = n + 1
      if good[i] == 1 then live = live + 1 end
      for e = G.eStart.p[i - 1], G.eStart.p[i] - 1 do
        local j = G.edges.p[e]
        if G.flag[j] ~= 2 and not f(lvl, st(j)) then escapes = escapes + 1; if good[j] == 1 then escLive = escLive + 1 end end
      end
    end
  end
  print(string.format("%s: состояний %d, живых %d, ходов, после которых признак пропадает, %d (из них в живое %d)", nm, n, live, escapes, escLive))
end
SV.freeGraph(G); require("ffi").C.free(good)
