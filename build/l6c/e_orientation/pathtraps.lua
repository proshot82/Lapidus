-- pathtraps.lua файл.lua — по шагам кратчайшего пути: сколько ходов ведут в скрытый тупик и в какую конфигурацию
-- деталей (без названий ходов; только вывод инструмента).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local function lost(st)
  for q, p in ipairs(lvl.pieces) do if p.movable and st.pos[q] == 0 then return true end end
  return def.visibleLoss and def.visibleLoss(lvl, st) or false
end
local function cfg(st)
  local t = {}
  for q, p in ipairs(lvl.pieces) do if p.movable then
    if st.pos[q] == 0 then t[#t+1] = p.tag .. "=смыт" else
    local x, y = R.xy(lvl, st.pos[q]); t[#t+1] = string.format("%s(%d,%d)%s%s", p.tag, x, y, st.fixed[q] and "F" or "", (not st.fixed[q] and st.asm[q] ~= q) and "*" or "") end end end
  return table.concat(t, " ")
end
local path, x = {}, G.firstWin
while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
table.insert(path, 1, 1)
for k = 1, #path - 1 do
  local s = path[k]
  local st = R.decode(lvl, G.keys[s])
  local nh, nv, nl, list = 0, 0, 0, {}
  for e = G.eStart.p[s - 1], G.eStart.p[s] - 1 do
    local j = G.edges.p[e]
    if G.flag[j] == 2 then nv = nv + 1
    elseif good[j] == 1 then nl = nl + 1
    else local sj = R.decode(lvl, G.keys[j]); if lost(sj) then nv = nv + 1 else nh = nh + 1; list[#list+1] = cfg(sj) end end
  end
  print(string.format("шаг %2d  [%s]  живых %d, скрытых %d, видимых %d  %s", k - 1, cfg(st), nl, nh, nv, (#list > 0) and ("→ " .. table.concat(list, " | ")) or ""))
end
SV.freeGraph(G); require("ffi").C.free(good)
