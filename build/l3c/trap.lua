-- build/l3c/trap.lua файл.lua [rule=narrow|d|e|wide] — скрытые ловушки у кратчайшего пути (без решений):
-- для каждого входа в скрытый тупик с пути: шаг пути, что изменилось (конфигурация мыла до → после),
-- размер скрытой области, глубина блуждания, сколько ходов минимум до «видимого» проигрыша (когда игрок это заметит).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local ruleName = (arg[2] or "rule=own"):match("rule=(%w+)")
local rule
if ruleName == "own" then rule = def.lost else
  rule = dofile("build/l3c/vis.lua").make(def.step, false, ({ narrow = {}, d = { d = true }, e = { e = true }, wide = { d = true, e = true } })[ruleName])
end
local G = SV.explore(lvl, 3000000)
if not G or not G.firstWin then print("нерешаем или ошибка") return end
local good = SV.goodSet(G)
local lostF, hidden = {}, {}
for i = 1, G.n do if G.flag[i] == 0 then
  local st = R.decode(lvl, G.keys[i]); lostF[i] = rule(lvl, st)
  if good[i] ~= 1 and not lostF[i] then hidden[i] = true end
end end
local function cfg(i)
  local st = R.decode(lvl, G.keys[i]); local t = {}
  for q, p in ipairs(lvl.pieces) do if p.movable then
    if st.pos[q] == 0 then t[#t+1] = "смыто" else local x, y = R.xy(lvl, st.pos[q]); t[#t+1] = x .. "," .. y end end end
  table.sort(t); return table.concat(t, " ")
end
local path, x = {}, G.firstWin
while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
table.insert(path, 1, 1)
local seenEntry = {}
for k = 1, #path - 1 do
  local s = path[k]
  for e = G.eStart.p[s - 1], G.eStart.p[s] - 1 do
    local j = G.edges.p[e]
    if hidden[j] and not seenEntry[j] then
      seenEntry[j] = true
      -- BFS внутри скрытых; до видимого проигрыша — BFS по всем недобитым
      local d, q, h, maxd = { [j] = 0 }, { j }, 1, 0
      while h <= #q do
        local u = q[h]; h = h + 1
        for e2 = G.eStart.p[u - 1], G.eStart.p[u] - 1 do
          local v = G.edges.p[e2]
          if hidden[v] and d[v] == nil then d[v] = d[u] + 1; if d[v] > maxd then maxd = d[v] end; q[#q + 1] = v end
        end
      end
      local d2, q2, h2, reveal = { [j] = 0 }, { j }, 1, nil
      while h2 <= #q2 and not reveal do
        local u = q2[h2]; h2 = h2 + 1
        for e2 = G.eStart.p[u - 1], G.eStart.p[u] - 1 do
          local v = G.edges.p[e2]
          if d2[v] == nil then d2[v] = d2[u] + 1
            if G.flag[v] == 0 and lostF[v] then reveal = d2[v]; break end
            if hidden[v] then q2[#q2 + 1] = v end
          end
        end
      end
      print(string.format("шаг %2d: %-12s → %-12s | скрытая область %5d, глубина %2d, до видимого проигрыша ≥ %s ходов",
        k - 1, cfg(s), cfg(j), #q, maxd, tostring(reveal)))
    end
  end
end
SV.freeGraph(G); require("ffi").C.free(good)
