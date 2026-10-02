-- vischeck.lua файл.lua — сколько ЖИВЫХ состояний помечено видимым проигрышем (должно быть 0) + сводка по конфигурациям.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local bad, agg = 0, {}
for i = 1, G.n do
  if G.flag[i] ~= 2 then
    local st = R.decode(lvl, G.keys[i])
    local v = def.visibleLoss and def.visibleLoss(lvl, st)
    if good[i] == 1 and v then bad = bad + 1 end
    local t = {}
    for q, p in ipairs(lvl.pieces) do if p.movable then
      if st.pos[q] == 0 then t[#t+1] = p.tag .. "=смыт" else
        local x, y = R.xy(lvl, st.pos[q]); t[#t+1] = string.format("%s(%d,%d)%s%s", p.tag, x, y, st.fixed[q] and "F" or "", (not st.fixed[q] and st.asm[q] ~= q) and "*" or "") end end end
    local k = table.concat(t, " ")
    local a = agg[k] or { 0, 0, 0 }; agg[k] = a
    local washed = false
    for q, p in ipairs(lvl.pieces) do if p.movable and st.pos[q] == 0 then washed = true end end
    if good[i] == 1 then a[1] = a[1] + 1 elseif washed or v then a[3] = a[3] + 1 else a[2] = a[2] + 1 end
  end
end
print("живых, помеченных видимыми: " .. bad)
if arg[2] then
  local list = {}
  for k, a in pairs(agg) do if a[1] + a[2] > 0 then list[#list+1] = { k, a } end end
  table.sort(list, function(a, b) return a[2][1] + a[2][2] > b[2][1] + b[2][2] end)
  print("конфигурация (* — свинчена с другой свободной)   живых  скрытых  видимых")
  for i = 1, math.min(tonumber(arg[2]), #list) do local a = list[i][2]; print(string.format("%-44s %6d %8d %8d", list[i][1], a[1], a[2], a[3])) end
end
SV.freeGraph(G); require("ffi").C.free(good)
