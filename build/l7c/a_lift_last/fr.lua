-- fr.lua файл.lua [фильтры...] — кадры кратчайшего решения с фильтрами (ТОЛЬКО вывод инструмента, для себя).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local F = {}
F.nohose = function(lvl, st, ns)
  local w = R.status(lvl, ns)
  if w.lapWet and not w.win and (w.headQ == nil or w.heelQ == nil) then return false end
  return true
end
for _, ab in ipairs(def.ablations or {}) do if ab.filter then F[ab.name] = ab.filter end end
local okA, A = pcall(dofile, "build/l7c/a_lift_last/abl10.lua")
if okA then for k, v in pairs(A) do F[k] = F[k] or v end end
local names = {}
for i = 2, #arg do names[#names + 1] = arg[i] end
local function combined(lvl, st, ns)
  for _, n in ipairs(names) do if not F[n](lvl, st, ns) then return false end end
  return true
end
local G = SV.explore(lvl, 3000000, (#names > 0) and combined or nil)
if not G or not G.firstWin then print("нет решения") return end
local SYM = { source = "S", fixture = "F", stub = "T", pipe = "=", fitting = "b", porcelain = "P" }
local JS = { "^", ">", "v", "<" }
local function show(s, label)
  local rows = {}
  for y = 1, lvl.H do rows[y] = {} for x = 1, lvl.W do local c = lvl.cell[(y-1)*lvl.W+x]; rows[y][x] = c == 1 and "#" or (c == 2 and "~" or ".") end end
  if not s.dead then for _, j in ipairs(R.jets(lvl, s)) do for _, c in ipairs(j.cells) do local x, y = R.xy(lvl, c); rows[y][x] = JS[j.dir] end end end
  for q, pp in ipairs(lvl.pieces) do if s.pos[q] ~= 0 then local x, y = R.xy(lvl, s.pos[q]); local ch = (pp.tag and pp.tag:sub(1,1)) or SYM[pp.kind]; if pp.movable then ch = s.fixed[q] and ch:upper() or ch:lower() else ch = SYM[pp.kind] end; rows[y][x] = ch end end
  if not s.dead then for i, c in ipairs(s.body) do local x, y = R.xy(lvl, c); rows[y][x] = (i == #s.body) and "H" or ((i == 1) and "f" or "o") end end
  local out = { label }
  for y = 1, lvl.H do out[#out+1] = table.concat(rows[y]) end
  return out
end
local path, x = {}, G.firstWin
while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
table.insert(path, 1, 1)
local frames = {}
for i, id in ipairs(path) do
  local st = R.decode(lvl, G.keys[id])
  local lab = (i == 1) and "start" or ((i-1) .. R.moveName(G.pmove[id]):gsub("heel", "f"):gsub("head", "H"):gsub(":", ""):sub(1, 3))
  frames[#frames+1] = show(st, lab)
end
local per = math.max(1, math.floor(130 / (lvl.W + 2)))
for k = 1, #frames, per do
  for line = 1, #frames[k] do
    local parts = {}
    for j = k, math.min(k + per - 1, #frames) do parts[#parts+1] = string.format("%-" .. (lvl.W + 2) .. "s", frames[j][line] or "") end
    print(table.concat(parts, ""))
  end
  print()
end
SV.freeGraph(G)
