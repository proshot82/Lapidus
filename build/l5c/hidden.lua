-- build/l5c/hidden.lua файл.lua [N] — скрытые тупики по общей линейке (tools/vislib.lua): группы по конфигурации
-- деталей и по одному кадру-образцу из каждой группы (ТОЛЬКО в вывод инструмента, для себя).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local VL = V.compute(lvl, G, def, good)
local function cfg(s)
  local t = {}
  for q, p in ipairs(lvl.pieces) do if p.movable then
    if s.pos[q] == 0 then t[#t + 1] = p.tag .. "=смыт" else
      local x, y = R.xy(lvl, s.pos[q]); t[#t + 1] = string.format("%s(%d,%d)%s", p.tag, x, y, s.fixed[q] and "F" or "") end end end
  return table.concat(t, " ")
end
local function show(s)
  local rows = {}
  for y = 1, lvl.H do rows[y] = {} for x = 1, lvl.W do local c = lvl.cell[(y - 1) * lvl.W + x]; rows[y][x] = c == 1 and "#" or (c == 2 and "~" or ".") end end
  for q, p in ipairs(lvl.pieces) do if s.pos[q] ~= 0 then
    local x, y = R.xy(lvl, s.pos[q]); local ch = p.source and "S" or (p.fixture and "D" or (p.what == "tee" and (s.fixed[q] and "T" or "t") or (s.fixed[q] and "P" or "p")))
    rows[y][x] = ch end end
  for i, c in ipairs(s.body) do local x, y = R.xy(lvl, c); rows[y][x] = (i == #s.body) and "H" or ((i == 1) and "f" or "o") end
  for y = 1, lvl.H do print("    " .. table.concat(rows[y])) end
end
local groups, order = {}, {}
for i = 1, G.n do
  if G.flag[i] ~= 2 and good[i] ~= 1 and not VL.newbie[i] then
    local s = VL.states[i]; local k = cfg(s)
    if not groups[k] then groups[k] = { n = 0, ex = s, exX = 0 }; order[#order + 1] = k end
    groups[k].n = groups[k].n + 1
    if VL.expert[i] then groups[k].exX = groups[k].exX + 1 end
  end
end
table.sort(order, function(a, b) return groups[a].n > groups[b].n end)
for k = 1, math.min(tonumber(arg[2] or 6), #order) do
  local g = groups[order[k]]
  print(string.format("%s: скрытых %d (из них видимы знатоку %d)", order[k], g.n, g.exX))
  show(g.ex)
end
SV.freeGraph(G); require("ffi").C.free(good)
