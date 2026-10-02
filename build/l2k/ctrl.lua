-- build/l2k/ctrl.lua файл — несущность ловушки: тот же уровень, но муфте запрещено прикручиваться к крюку
-- (фильтр ходов). Печатает ходы, долю скрытых и умную обезьяну с запретом и без.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local def = dofile(arg[1])
local function run(filter)
  local lvl = R.compile(def)
  local G = SV.explore(lvl, 3000000, filter)
  local good = SV.goodSet(G)
  local VL = V.compute(lvl, G, def, good)
  local EX = V.measure(G, good, VL.newbie)
  local r = string.format("ходов %d, состояний %d, скрытых %.0f %%, умная обезьяна %.2f %%", EX.opt, G.n, EX.hiddenPct, EX.smart)
  SV.freeGraph(G)
  return r
end
local function noTrap(lvl, st, ns)
  for q, p in ipairs(lvl.pieces) do
    if p.movable and ns.fixed[q] then
      for d = 1, 4 do local t = lvl.nb[ns.pos[q]][d]
        for r, pr in ipairs(lvl.pieces) do if pr.kind == "stub" and pr.start == t then return false end end
      end
    end
  end
  return true
end
print("как есть:              " .. run(nil))
print("муфта к крюку не липнет: " .. run(noTrap))
