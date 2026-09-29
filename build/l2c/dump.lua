-- build/l2c/dump.lua файл.lua [all|dead|hidden|live] [N] — картинки состояний кв. 2 (только для вывода инструмента).
-- Группирует тупики по классу (visibleLoss файла) и печатает до N примеров; для каждого — глубина от старта
-- и признак «рядом с кратчайшим путём».
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local mode = arg[2] or "hidden"
local N = tonumber(arg[3] or 40)
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local SYM = { source = "S", fixture = "F", stub = "T", pipe = "=", fitting = "b", porcelain = "P" }
local function rows(s)
  local r = {}
  for y = 1, lvl.H do r[y] = {} for x = 1, lvl.W do local c = lvl.cell[(y-1)*lvl.W+x]; r[y][x] = c == 1 and "#" or (c == 2 and "~" or ".") end end
  for q, pp in ipairs(lvl.pieces) do if s.pos[q] ~= 0 then local x, y = R.xy(lvl, s.pos[q]); r[y][x] = SYM[pp.kind] end end
  if not s.dead then for i, c in ipairs(s.body) do local x, y = R.xy(lvl, c); r[y][x] = (i == #s.body) and "H" or ((i == 1) and "f" or "o") end end
  local out = {}
  for y = 1, lvl.H do out[y] = table.concat(r[y]) end
  return out
end
local path, x = {}, G.firstWin
while x and x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
table.insert(path, 1, 1)
local onPath = {}
for k, id in ipairs(path) do onPath[id] = k - 1 end
local nearPath = {}
for k, id in ipairs(path) do
  for e = G.eStart.p[id - 1], G.eStart.p[id] - 1 do local j = G.edges.p[e]; if not onPath[j] then nearPath[j] = nearPath[j] or (k - 1) end end
end
local pick = {}
for i = 1, G.n do
  if G.flag[i] ~= 2 then
    local st = R.decode(lvl, G.keys[i])
    local vis = def.visibleLoss and def.visibleLoss(lvl, st) or false
    local ok = (mode == "all") or (mode == "live" and good[i] == 1) or (mode == "dead" and good[i] ~= 1)
      or (mode == "hidden" and good[i] ~= 1 and not vis) or (mode == "visible" and good[i] ~= 1 and vis)
    if ok then pick[#pick + 1] = { i = i, st = st, vis = vis } end
  end
end
print(string.format("%s: %d состояний", mode, #pick))
local per = math.max(1, math.floor(120 / (lvl.W + 2)))
for k = 1, math.min(N, #pick), per do
  local frames = {}
  for j = k, math.min(k + per - 1, N, #pick) do
    local p = pick[j]
    local lab = string.format("%d d%d%s%s", p.i, G.depth[p.i], nearPath[p.i] and ("n" .. nearPath[p.i]) or "", good[p.i] == 1 and "+" or (p.vis and "V" or "X"))
    local f = rows(p.st); table.insert(f, 1, lab); frames[#frames + 1] = f
  end
  for line = 1, lvl.H + 1 do
    local parts = {}
    for _, f in ipairs(frames) do parts[#parts + 1] = string.format("%-" .. (lvl.W + 2) .. "s", f[line]) end
    print(table.concat(parts))
  end
  print()
end
SV.freeGraph(G); require("ffi").C.free(good)
