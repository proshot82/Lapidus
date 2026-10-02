-- build/l7e/cfg.lua файл.lua [N] — достижимые конфигурации деталей (позиции, закреплённость), число состояний в каждой.
-- Для диагностики нерешаемых кандидатов: дошла ли деталь до места. Порядка ходов не печатает.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local agg, first = {}, {}
for i = 1, G.n do if G.flag[i] ~= 2 then
  local st = R.decode(lvl, G.keys[i])
  local t = {}
  for q, p in ipairs(lvl.pieces) do if p.movable then
    if st.pos[q] == 0 then t[#t+1] = p.tag .. "=смыт" else
    local x, y = R.xy(lvl, st.pos[q]); t[#t+1] = string.format("%s(%d,%d)%s", p.tag, x, y, st.fixed[q] and "F" or "") end end end
  local k = table.concat(t, " ")
  agg[k] = (agg[k] or 0) + 1
  if not first[k] or G.depth[i] < first[k] then first[k] = G.depth[i] end
end end
local list = {}
for k, a in pairs(agg) do list[#list+1] = { k, a } end
table.sort(list, function(a, b) return a[2] > b[2] end)
local filt = arg[3]
local shown = 0
for i = 1, #list do
  if not filt or list[i][1]:find(filt, 1, true) then
    print(string.format("%-40s %6d  глубина %d", list[i][1], list[i][2], first[list[i][1]]))
    shown = shown + 1; if shown >= tonumber(arg[2] or 40) then break end
  end
end
print("всего конфигураций", #list, "состояний", G.n)
