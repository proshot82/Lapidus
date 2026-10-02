-- probe2.lua файл.lua "условие" — кадры пути к ближайшему состоянию с условием (ТОЛЬКО вывод инструмента).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local Q = {}
for q, p in ipairs(lvl.pieces) do if p.tag then Q[p.tag] = q end end
local cond = assert(load("return function(st, fx, at, L) return " .. arg[2] .. " end"))()
local first
for i = 1, G.n do
  local st = R.decode(lvl, G.keys[i])
  local function fx(t) return st.fixed[Q[t]] end
  local function at(t, x, y) return st.pos[Q[t]] == R.idx(lvl, x, y) end
  local function L(x, y) local c = R.idx(lvl, x, y); for _, b in ipairs(st.body) do if b == c then return true end end return false end
  if cond(st, fx, at, L) and (not first or G.depth[i] < G.depth[first]) then first = i end
end
if not first then print("нет") return end
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
local path, x = {}, first
while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
table.insert(path, 1, 1)
local frames = {}
for i, id in ipairs(path) do
  frames[#frames+1] = show(R.decode(lvl, G.keys[id]), (i == 1) and "start" or ((i-1) .. R.moveName(G.pmove[id]):gsub("heel", "f"):gsub("head", "H"):gsub(":", ""):sub(1, 3)))
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
