-- двери с кратчайшего пути: шаг, ход-дверь, картинка состояния-двери и глубина (только вывод инструмента)
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local VL = V.compute(lvl, G, def, good)
local path, x = {}, G.firstWin
while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
table.insert(path, 1, 1)
local function show(s)
  local rows = {}
  for y = 1, lvl.H do rows[y] = {} for xx = 1, lvl.W do local c = lvl.cell[(y-1)*lvl.W+xx]; rows[y][xx] = c == 1 and "#" or (c == 2 and "~" or ".") end end
  for q, pp in ipairs(lvl.pieces) do if s.pos[q] ~= 0 then local xx, y = R.xy(lvl, s.pos[q]); local ch = pp.tag and pp.tag:sub(1,1) or (pp.kind == "source" and "S" or "F"); if pp.movable and s.fixed[q] then ch = ch:upper() end; rows[y][xx] = ch end end
  for i, c in ipairs(s.body) do local xx, y = R.xy(lvl, c); rows[y][xx] = (i == #s.body) and "H" or ((i == 1) and "f" or "o") end
  local out = {} for y = 1, lvl.H do out[y] = table.concat(rows[y]) end
  return out
end
local blocks = {}
for k = 1, #path - 1 do
  local s = path[k]
  for e = G.eStart.p[s - 1], G.eStart.p[s] - 1 do
    local j = G.edges.p[e]
    if G.flag[j] ~= 2 and good[j] ~= 1 and not VL.newbie[j] then
      local b = show(R.decode(lvl, G.keys[j]))
      table.insert(b, 1, "шаг " .. (k - 1) .. " " .. R.moveName(G.pmove[j]))
      blocks[#blocks + 1] = b
    end
  end
end
local per = math.max(1, math.floor(130 / (lvl.W + 4)))
for k = 1, #blocks, per do
  for line = 1, #blocks[k] do
    local parts = {}
    for j = k, math.min(k + per - 1, #blocks) do parts[#parts+1] = string.format("%-" .. (lvl.W + 4) .. "s", blocks[j][line] or "") end
    print(table.concat(parts))
  end
end
