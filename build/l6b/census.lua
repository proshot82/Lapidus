-- build/l6b/census.lua файл.lua — состояния по конфигурациям деталей: живые / скрытые / видимые.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local function lost(st)
  -- def.washOk: смытая деталь сама по себе не проигрыш (в кв. 3 одно мыло уходит в слив по замыслу) — решает def.visibleLoss
  if not def.washOk then
    for q, p in ipairs(lvl.pieces) do if p.movable and st.pos[q] == 0 then return true end end
  end
  return def.visibleLoss and def.visibleLoss(lvl, st) or false
end
local agg = {}
for i = 1, G.n do
  if G.flag[i] ~= 2 then
    local st = R.decode(lvl, G.keys[i])
    local t = {}
    for q, p in ipairs(lvl.pieces) do if p.movable then
      if st.pos[q] == 0 then t[#t+1] = (p.tag or p.what) .. "=смыт" else
        local x, y = R.xy(lvl, st.pos[q]); t[#t+1] = string.format("%s(%d,%d)%s", p.tag or p.what, x, y, st.fixed[q] and "F" or "") end end end
    local k = table.concat(t, " ")
    local a = agg[k] or { 0, 0, 0 }; agg[k] = a
    if good[i] == 1 then a[1] = a[1] + 1 elseif lost(st) then a[3] = a[3] + 1 else a[2] = a[2] + 1 end
  end
end
local list = {}
for k, a in pairs(agg) do if a[1] + a[2] > 0 then list[#list+1] = { k, a } end end
table.sort(list, function(a, b) return a[2][1] + a[2][2] > b[2][1] + b[2][2] end)
print("конфигурация деталей                      живых  скрытых  видимых")
for i = 1, math.min(tonumber(arg[2] or 25), #list) do local a = list[i][2]; print(string.format("%-40s %6d %8d %8d", list[i][1], a[1], a[2], a[3])) end
SV.freeGraph(G); require("ffi").C.free(good)
