-- cls.lua файл.lua [N] — классы скрытых тупиков новичка: по расстановке деталей — сколько живых / скрытых / видимых
-- (живые в той же расстановке = тупик из-за положения Лапидуса; 0 живых = расстановка деталей обречена).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local GN = dofile("build/l7c/d_tee_lift/gnov.lua")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local nov = GN.compute(lvl, G, def)
local agg = {}
local totH, totHdoomed = 0, 0
for i = 1, G.n do
  if G.flag[i] ~= 2 then
    local st = R.decode(lvl, G.keys[i])
    local t = {}
    for q, p in ipairs(lvl.pieces) do if p.movable then
      if st.pos[q] == 0 then t[#t+1] = (p.tag or p.what) .. "=смыт" else
        local x, y = R.xy(lvl, st.pos[q]); t[#t+1] = string.format("%s(%d,%d)%s%s", p.tag or p.what, x, y, st.fixed[q] and "F" or "", st.asm[q] ~= q and ("~" .. st.asm[q]) or "") end end end
    local k = table.concat(t, " ")
    local a = agg[k] or { 0, 0, 0 }; agg[k] = a
    if good[i] == 1 then a[1] = a[1] + 1 elseif nov[i] then a[3] = a[3] + 1 else a[2] = a[2] + 1 end
  end
end
local list = {}
for k, a in pairs(agg) do list[#list + 1] = { k, a }; totH = totH + a[2]; if a[1] == 0 then totHdoomed = totHdoomed + a[2] end end
table.sort(list, function(a, b) return a[2][2] > b[2][2] end)
print(string.format("скрытых всего %d, из них в обречённых расстановках деталей %d (%.0f %%)", totH, totHdoomed, 100 * totHdoomed / math.max(1, totH)))
print("расстановка деталей                                живых  скрытых  видимых")
for i = 1, math.min(tonumber(arg[2] or 20), #list) do local a = list[i][2]; print(string.format("%-48s %6d %8d %8d", list[i][1], a[1], a[2], a[3])) end
SV.freeGraph(G); require("ffi").C.free(good)
