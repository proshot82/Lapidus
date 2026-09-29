-- build/l2d/frames.lua файл [N] — кадры кратчайшего решения (только в терминал), либо N случайных достижимых состояний если нерешаем.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local MK = dofile("build/l2d/mk.lua")
local d = dofile(arg[1]); if d.rows then d = MK.build(d.rows, d.opts) end
local lvl = R.compile(d)
local G = SV.explore(lvl, 3000000)
local SYM = { source = "S", fixture = "F", stub = "T", pipe = "=", fitting = "b", porcelain = "P" }
local function show(s, label)
  local rows = {}
  for y = 1, lvl.H do rows[y] = {} for x = 1, lvl.W do local c = lvl.cell[(y-1)*lvl.W+x]; rows[y][x] = c == 1 and "#" or (c == 2 and "~" or ".") end end
  for q, pp in ipairs(lvl.pieces) do if s.pos[q] ~= 0 then local x, y = R.xy(lvl, s.pos[q]); local ch = SYM[pp.kind]; if pp.kind == "stub" then local dd; for k, v in pairs(pp.ports) do dd = ({"^",">","v","<"})[k] .. v end; ch = dd:sub(1,1) end; if pp.movable then ch = s.fixed[q] and ch:upper() or ch:lower() end; rows[y][x] = ch end end
  if not s.dead then for i, c in ipairs(s.body) do local x, y = R.xy(lvl, c); rows[y][x] = (i == #s.body) and "H" or ((i == 1) and "f" or "o") end end
  local out = { label }
  for y = 1, lvl.H do out[#out+1] = table.concat(rows[y]) end
  return out
end
local frames = {}
if G.firstWin then
  local path, x = {}, G.firstWin
  while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
  table.insert(path, 1, 1)
  for i, id in ipairs(path) do
    local st = R.decode(lvl, G.keys[id])
    local lab = (i == 1) and "start" or ((i-1) .. R.moveName(G.pmove[id]):gsub("heel", "f"):gsub("head", "H"):gsub(":", ""):sub(1, 3))
    frames[#frames+1] = show(st, lab)
  end
else
  local N = tonumber(arg[2] or 12)
  print("нерешаем; состояний " .. G.n .. "; самые глубокие:")
  local ids = {}
  for i = 1, G.n do ids[#ids+1] = i end
  table.sort(ids, function(a, b) return G.depth[a] > G.depth[b] end)
  for k = 1, math.min(N, #ids) do local id = ids[k]; frames[#frames+1] = show(R.decode(lvl, G.keys[id]), "d" .. G.depth[id]) end
end
local per = math.max(1, math.floor(110 / (lvl.W + 2)))
for k = 1, #frames, per do
  for line = 1, #frames[k] do
    local parts = {}
    for j = k, math.min(k + per - 1, #frames) do parts[#parts+1] = string.format("%-" .. (lvl.W + 2) .. "s", frames[j][line] or "") end
    print(table.concat(parts, ""))
  end
  print()
end
