-- build/l4e/alt.lua файл.lua — доля скрытых при альтернативной (более строгой) мерке: дополнительно видимым считается
-- «угольник лежит на полу коридора» (по логике скептика кв. 4: «нечем поднять» — угольнику на машинку с пола не попасть).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local VL = V.compute(lvl, G, def, good)
local qe
for q, p in ipairs(lvl.pieces) do if p.tag == "elb" then qe = q end end
local alt = {}
for i = 1, G.n do
  if G.flag[i] ~= 2 then
    local st = VL.states[i]
    local c = st.pos[qe]
    local onFloor = c ~= 0 and not st.fixed[qe] and select(2, R.xy(lvl, c)) >= 4
    alt[i] = VL.newbie[i] or (good[i] ~= 1 and onFloor)
  end
end
local a = V.measure(G, good, VL.newbie)
local b = V.measure(G, good, alt)
print(string.format("мерка файла: скрытых %.0f %%, глубина %d [%s] | угольник на полу видим: скрытых %.0f %%, глубина %d [%s]",
  a.hiddenPct, a.maxDeep, a.deepList, b.hiddenPct, b.maxDeep, b.deepList))
SV.freeGraph(G); require("ffi").C.free(good)
