-- build/l7v_f/marks.lua файл.lua — мерка новичка + «видно с одного взгляда» по классам: скрытых и глубина.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local VL = V.compute(lvl, G, def, good)
local Q = {} for q, p in ipairs(lvl.pieces) do if p.tag then Q[p.tag] = q end end
local function wrongPair(s) return s.pos[Q.elb] ~= 0 and s.pos[Q.plug] ~= 0 and s.asm[Q.elb] == s.asm[Q.plug] end
local function allFixed(s) return s.fixed[Q.elb] and s.fixed[Q.plug] and s.fixed[Q.nip] end
local variants = {
  { "новичок (vislib, карман 4)", function(s) return false end },
  { "+ все три прикручены не так (B)", function(s) return allFixed(s) end },
  { "+ угольник и заглушка свинчены, свободны (A)", function(s) return wrongPair(s) and not allFixed(s) end },
  { "+ A и B (любая неверная пара)", function(s) return wrongPair(s) end },
}
for _, v in ipairs(variants) do
  local lost = {}
  for i = 1, G.n do if G.flag[i] ~= 2 then local s = R.decode(lvl, G.keys[i]); lost[i] = VL.newbie[i] or (good[i] ~= 1 and v[2](s)) end end
  local m = V.measure(G, good, lost)
  print(string.format("%-48s скрытых %4d (%.1f %%) обезьяна %.3f глубина %d [%s]", v[1], m.hid, m.hiddenPct, m.smart, m.maxDeep, m.deepList))
end
SV.freeGraph(G); require("ffi").C.free(good)
