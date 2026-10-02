-- build/l8b/cfg.lua файл.lua — перепись положений деталей по всем достижимым состояниям (решаем уровень или нет), без ходов.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 1500000)
local agg = {}
for i = 1, G.n do
  if G.flag[i] ~= 2 then
    local s = R.decode(lvl, G.keys[i])
    local t = {}
    for q, p in ipairs(lvl.pieces) do if p.movable then
      if s.pos[q] == 0 then t[#t+1] = p.tag .. "=смыт" else local x, y = R.xy(lvl, s.pos[q]); t[#t+1] = string.format("%s(%d,%d)%s", p.tag, x, y, s.fixed[q] and "F" or "") end end end
    local k = table.concat(t, " ")
    agg[k] = (agg[k] or 0) + 1
  end
end
local l = {}
for k, v in pairs(agg) do l[#l+1] = { k, v } end
table.sort(l, function(a, b) return a[2] > b[2] end)
print(string.format("состояний %d, решаем: %s, конфигураций деталей %d", G.n, G.firstWin and "да" or "нет", #l))
for i = 1, math.min(tonumber(arg[2] or 20), #l) do print(string.format("  %6d  %s", l[i][2], l[i][1])) end
SV.freeGraph(G)
