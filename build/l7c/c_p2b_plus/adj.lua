-- adj.lua файл.lua — соседи состояний кратчайшего пути: для каждого шага — сколько соседей живые/мёртвые
-- и для мёртвых (скрытых по разметке файла) — глубина скрытой ветки; плюс кадр первого мёртвого соседа по запросу.
-- Только вывод инструмента.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
do local e = R.validate(lvl); if #e > 0 then print("ОШИБКИ: " .. table.concat(e, "; ")); os.exit(0) end end
local G = SV.explore(lvl, 3000000)
if not G or not G.firstWin then print("нерешаем"); os.exit(0) end
local good = SV.goodSet(G)
local E, ES = G.edges.p, G.eStart.p
local path, x = {}, G.firstWin
while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
table.insert(path, 1, 1)
local function lost(st)
  for q, p in ipairs(lvl.pieces) do if p.movable and st.pos[q] == 0 then return true end end
  return def.visibleLoss and def.visibleLoss(lvl, st) or false
end
local hidden = {}
local function isHidden(i)
  if hidden[i] == nil then
    if G.flag[i] ~= 0 or good[i] == 1 then hidden[i] = false else hidden[i] = not lost(R.decode(lvl, G.keys[i])) end
  end
  return hidden[i]
end
local function depthFrom(j)
  local d, q, h, maxd = { [j] = 0 }, { j }, 1, 0
  while h <= #q do
    local u = q[h]; h = h + 1
    for e = ES[u - 1], ES[u] - 1 do
      local v = E[e]
      if d[v] == nil and isHidden(v) then d[v] = d[u] + 1; if d[v] > maxd then maxd = d[v] end; q[#q + 1] = v end
    end
  end
  return maxd, #q
end
local out = {}
for k = 1, #path - 1 do
  local s = path[k]
  local live, dead, hid, best = 0, 0, 0, -1
  for e = ES[s - 1], ES[s] - 1 do
    local j = E[e]
    if G.flag[j] == 2 then dead = dead + 1
    elseif good[j] == 1 then live = live + 1
    else dead = dead + 1; if isHidden(j) then hid = hid + 1; local d = depthFrom(j); if d > best then best = d end end end
  end
  out[#out + 1] = string.format("%d:%d/%d%s", k - 1, live, dead, hid > 0 and ("(скр" .. hid .. ",гл" .. best .. ")") or "")
end
print("шаг:живых/мёртвых соседей " .. table.concat(out, " "))
SV.freeGraph(G); require("ffi").C.free(good)
