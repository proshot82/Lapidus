-- build/l4d/trace3.lua файл.lua — цепочка конфигураций к первому ЖИВОМУ состоянию, где вторая деталь на полу (ряд входа),
-- а муфта ещё на антресоли (ряд 3); и от него — до победы (конфигурации). Только терминал.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local qc, qn, S
for q, p in ipairs(lvl.pieces) do if p.what == "coupling" then qc = q elseif p.movable then qn = q end; if p.source then S = p.start end end
local T = lvl.nb[lvl.nb[S][1]][1]
local W = lvl.W
local function row(c) return math.floor((c - 1) / W) + 1 end
local function cfg(st)
  local t = {}
  for q, p in ipairs(lvl.pieces) do if p.movable then local x, y = R.xy(lvl, st.pos[q]); t[#t+1] = string.format("%s(%d,%d)%s", p.tag, x, y, st.fixed[q] and "F" or "") end end
  local b = st.body; local hx, hy = R.xy(lvl, b[#b]); local fx, fy = R.xy(lvl, b[1])
  return table.concat(t, " ") .. string.format("  L:ноги(%d,%d)голова(%d,%d)", fx, fy, hx, hy)
end
local best
for i = 1, G.n do
  if G.flag[i] ~= 2 and good[i] == 1 then
    local st = R.decode(lvl, G.keys[i])
    if not st.fixed[qc] and not st.fixed[qn] and row(st.pos[qc]) == 3 and row(st.pos[qn]) == row(T) and (not best or G.depth[i] < G.depth[best]) then best = i end
  end
end
if not best then print("нет") return end
local path, x = {}, best
while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
table.insert(path, 1, 1)
local last
for _, s in ipairs(path) do local c = cfg(R.decode(lvl, G.keys[s])); if c ~= last then print(G.depth[s] .. ": " .. c); last = c end end
-- дальше: BFS от best по живым до победы
print("--- дальше к победе:")
local par, q, h = { [best] = 0 }, { best }, 1
local winI
while h <= #q do
  local u = q[h]; h = h + 1
  if G.flag[u] == 1 then winI = u break end
  for e = G.eStart.p[u - 1], G.eStart.p[u] - 1 do local v = G.edges.p[e]; if par[v] == nil and (good[v] == 1 or G.flag[v] == 1) then par[v] = u; q[#q + 1] = v end end
end
local p2, y = {}, winI
while y ~= 0 do table.insert(p2, 1, y); y = par[y] end
last = nil
for _, s in ipairs(p2) do local c = cfg(R.decode(lvl, G.keys[s])); if c ~= last then print(G.depth[s] .. ": " .. c); last = c end end
SV.freeGraph(G); require("ffi").C.free(good)
