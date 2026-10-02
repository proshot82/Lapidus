-- build/l3v2/bear.lua — несущность единственной ошибки: запрет «смыть мыло, на котором ничего не лежит» —
-- насколько он облегчает уровень (скрытых, обезьяна) при той же линейке.
package.path = "./?.lua;" .. package.path
local R = require("core.rules"); local SV = require("solver.solve"); local V = require("tools.vislib")
local def = dofile(arg[1] or "build/l3d/s8.lua")
local lvl = R.compile(def)
local SQ = {} for q, p in ipairs(lvl.pieces) do if p.porcelain then SQ[#SQ+1] = q end end
local function k1(l, a, b)
  for _, r in ipairs(SQ) do if a.pos[r] ~= 0 and b.pos[r] == 0 then
    local up = l.nb[a.pos[r]][1]; local on = false
    for _, r2 in ipairs(SQ) do if a.pos[r2] == up then on = true end end
    if not on then return false end end end
  return true end
for _, f in ipairs({ { "база", nil }, { "без ошибки (смыв только из-под стопки)", k1 } }) do
  local G = SV.explore(lvl, 3000000, f[2]); local good = SV.goodSet(G)
  local VL = V.compute(lvl, G, def, good); local m = V.measure(G, good, VL.newbie)
  print(string.format("%-40s ходов %d, скрытых %.1f %%, обезьяна %.3f %%, глубина %d", f[1], m.opt, m.hiddenPct, m.smart, m.maxDeep))
  SV.freeGraph(G); require("ffi").C.free(good)
end
