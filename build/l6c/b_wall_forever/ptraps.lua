-- ptraps.lua файл.lua — вдоль кратчайшего пути: для каждого шага — альтернативные ходы и их класс
-- (живой / скрытый тупик [размер области, глубина] / видимый / смыло). Только вывод инструмента.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
if not G.firstWin then print("НЕРЕШАЕМ", G.n) return end
local states = {}
local function st(i) states[i] = states[i] or R.decode(lvl, G.keys[i]); return states[i] end
local function lost(s)
  for q, p in ipairs(lvl.pieces) do if p.movable and s.pos[q] == 0 then return true end end
  return def.visibleLoss and def.visibleLoss(lvl, s) or false
end
local function hidden(i) return G.flag[i] == 0 and good[i] ~= 1 and not lost(st(i)) end
local function region(j)
  local d, q, h, maxd = { [j] = 0 }, { j }, 1, 0
  while h <= #q do
    local u = q[h]; h = h + 1
    for e = G.eStart.p[u - 1], G.eStart.p[u] - 1 do
      local v = G.edges.p[e]
      if hidden(v) and d[v] == nil then d[v] = d[u] + 1; if d[v] > maxd then maxd = d[v] end; q[#q + 1] = v end
    end
  end
  return #q, maxd
end
local function cfg(s) local t = {} for q, p in ipairs(lvl.pieces) do if p.movable then t[#t+1] = s.pos[q] .. (s.fixed[q] and "F" or "") end end return table.concat(t, ",") end
local path, x = {}, G.firstWin
while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
table.insert(path, 1, 1)
for k = 1, #path - 1 do
  local s = path[k]
  local parts = {}
  for m = 1, 8 do
    local mm = R.MOVES[m]
    local ns = R.move(lvl, st(s), mm.which, mm.dir)
    local j = ns and G.index[R.key(ns)]
    if j then
    local nm = R.moveName(m):gsub("heel", "f"):gsub("head", "H")
    local ev = cfg(st(s)) ~= cfg(st(j)) and "*" or ""
    local tag
    if j == path[k + 1] then tag = "[" .. nm .. ev .. "]"
    elseif G.flag[j] == 1 then tag = nm .. "=WIN"
    elseif G.flag[j] == 2 then tag = nm .. ev .. "=смыт"
    elseif good[j] == 1 then tag = nm .. ev .. "=ок"
    elseif lost(st(j)) then tag = nm .. ev .. "=вид"
    else local n, d = region(j); tag = nm .. ev .. "=СКР" .. n .. "/" .. d end
    parts[#parts + 1] = tag
    end
  end
  print(string.format("%2d: %s", k - 1, table.concat(parts, "  ")))
end
SV.freeGraph(G); require("ffi").C.free(good)
