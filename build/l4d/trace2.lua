-- build/l4d/trace2.lua файл.lua x y [F] — цепочка конфигураций (детали + концы Лапидуса) к первому состоянию,
-- где ниппель в (x,y) [закреплён]. Только в терминал.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local qn
for q, p in ipairs(lvl.pieces) do if p.what == "nipple" then qn = q end end
local c = R.idx(lvl, tonumber(arg[2]), tonumber(arg[3])); local f = arg[4] == "F"
local function cfg(st)
  local t = {}
  for q, p in ipairs(lvl.pieces) do if p.movable then local x, y = R.xy(lvl, st.pos[q]); t[#t+1] = string.format("%s(%d,%d)%s", p.tag, x, y, st.fixed[q] and "F" or "") end end
  local b = {}
  for _, cc in ipairs(st.body) do local x, y = R.xy(lvl, cc); b[#b+1] = string.format("(%d,%d)", x, y) end
  return table.concat(t, " ") .. "  тело ноги→голова " .. table.concat(b, "")
end
local best
for i = 1, G.n do
  if G.flag[i] ~= 2 then
    local st = R.decode(lvl, G.keys[i])
    if st.pos[qn] == c and (st.fixed[qn] or false) == f then if not best or G.depth[i] < G.depth[best] then best = i end end
  end
end
if best then
  local path, x = {}, best
  while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
  table.insert(path, 1, 1)
  for _, s in ipairs(path) do print(G.depth[s] .. ": " .. cfg(R.decode(lvl, G.keys[s]))) end
else print("недостижимо") end
SV.freeGraph(G)
