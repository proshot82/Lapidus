-- cfgs.lua файл.lua — достижимые конфигурации деталей (для себя): сколько состояний, мин. глубина.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local agg = {}
for i = 1, G.n do
  if G.flag[i] ~= 2 then
    local st = R.decode(lvl, G.keys[i])
    local t = {}
    for q, p in ipairs(lvl.pieces) do if p.movable then
      if st.pos[q] == 0 then t[#t+1] = (p.tag or p.what) .. "=x" else
        local x, y = R.xy(lvl, st.pos[q]); t[#t+1] = string.format("%s(%d,%d)%s", p.tag or p.what, x, y, st.fixed[q] and "F" or "") end end end
    local k = table.concat(t, " ")
    local a = agg[k] or { 0, 1e9 }; agg[k] = a
    a[1] = a[1] + 1; if G.depth[i] < a[2] then a[2] = G.depth[i] end
  end
end
local list = {}
for k, a in pairs(agg) do list[#list+1] = { k, a } end
table.sort(list, function(a, b) return a[2][2] < b[2][2] end)
print("states", G.n, "win", G.firstWin and G.depth[G.firstWin] or "-")
for i = 1, math.min(tonumber(arg[2] or 40), #list) do print(string.format("%-40s n=%6d d=%3d", list[i][1], list[i][2][1], list[i][2][2])) end
