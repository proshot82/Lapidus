-- build/l8b/sol.lua файл.lua [nohose] — кадры кратчайшего решения (при nohose — по правилам без брандспойта). Только терминал.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local F = dofile("build/l8a/filt.lua")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 1500000, arg[2] == "nohose" and F.noHose or nil)
if not G or not G.firstWin then print("нерешаем") return end
local path, x = {}, G.firstWin
while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
table.insert(path, 1, 1)
local function show(s)
  local rows = {}
  for y = 1, lvl.H do rows[y] = {} for x2 = 1, lvl.W do local c = lvl.cell[(y-1)*lvl.W+x2]; rows[y][x2] = c == 1 and "#" or (c == 2 and "~" or ".") end end
  for _, j in ipairs(R.jets(lvl, s)) do for _, c in ipairs(j.cells) do local xx, yy = R.xy(lvl, c); rows[yy][xx] = ({ "^", ">", "v", "<" })[j.dir] end end
  for q, p in ipairs(lvl.pieces) do if s.pos[q] ~= 0 then local xx, yy = R.xy(lvl, s.pos[q]); local ch = p.kind == "source" and "S" or (p.kind == "fixture" and "F" or (p.kind == "stub" and "T" or (p.tag or "?"):sub(1,1))); if p.movable then ch = s.fixed[q] and ch:upper() or ch:lower() end; rows[yy][xx] = ch end end
  for i, c in ipairs(s.body) do local xx, yy = R.xy(lvl, c); rows[yy][xx] = (i == #s.body) and "H" or ((i == 1) and "f" or "o") end
  local out = {}
  for y = 1, lvl.H do out[y] = table.concat(rows[y]) end
  return out
end
local frames = {}
for i, id in ipairs(path) do
  local st = R.decode(lvl, G.keys[id])
  local lab = (i == 1) and "start" or ((i - 1) .. " " .. R.moveName(G.pmove[id]):gsub("heel", "f"):gsub("head", "H"))
  local fr = show(st); table.insert(fr, 1, lab); frames[#frames + 1] = fr
end
local per = math.max(1, math.floor(120 / (lvl.W + 2)))
for k = 1, #frames, per do
  for line = 1, #frames[k] do
    local parts = {}
    for j = k, math.min(k + per - 1, #frames) do parts[#parts + 1] = string.format("%-" .. (lvl.W + 2) .. "s", frames[j][line] or "") end
    print(table.concat(parts, ""))
  end
  print()
end
SV.freeGraph(G)
