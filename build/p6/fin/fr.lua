-- кадры кратчайшего решения (только вывод инструмента). luajit build/p6/fin/fr.lua файл
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
if not G.firstWin then print("НЕРЕШ", G.n) return end
local path, x = {}, G.firstWin
while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
table.insert(path, 1, 1)
local SYM = { source = "S", fixture = "F", stub = "T", pipe = "=", fitting = "b", porcelain = "P" }
local function show(s, label)
  local rows = {}
  for y = 1, lvl.H do rows[y] = {} for xx = 1, lvl.W do local c = lvl.cell[(y-1)*lvl.W+xx]; rows[y][xx] = c == 1 and "#" or (c == 2 and "~" or ".") end end
  for q, pp in ipairs(lvl.pieces) do if s.pos[q] ~= 0 then local xx, y = R.xy(lvl, s.pos[q]); local ch = pp.tag and pp.tag:sub(1,1) or SYM[pp.kind]; if pp.movable and s.fixed[q] then ch = ch:upper() end; rows[y][xx] = ch end end
  for i, c in ipairs(s.body) do local xx, y = R.xy(lvl, c); rows[y][xx] = (i == #s.body) and "H" or ((i == 1) and "f" or "o") end
  local out = { label }
  for y = 1, lvl.H do out[#out+1] = table.concat(rows[y]) end
  return out
end
local frames = {}
for i, id in ipairs(path) do
  local st = R.decode(lvl, G.keys[id])
  frames[#frames+1] = show(st, tostring(i-1))
end
local per = math.max(1, math.floor(130 / (lvl.W + 2)))
for k = 1, #frames, per do
  for line = 1, #frames[k] do
    local parts = {}
    for j = k, math.min(k + per - 1, #frames) do parts[#parts+1] = string.format("%-" .. (lvl.W + 2) .. "s", frames[j][line] or "") end
    print(table.concat(parts, ""))
  end
end
print("ходов", #path-1, "состояний", G.n)
