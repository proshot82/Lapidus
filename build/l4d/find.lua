-- build/l4d/find.lua файл.lua класс — печатает конфигурации живых состояний, где муфта свободна не на полу (ряд не входа),
-- а ниппель на полу; и цепочку конфигураций к первому такому (только в терминал).
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
local seen = {}
local best, bestd = nil, 1e9
for i = 1, G.n do
  if G.flag[i] ~= 2 and good[i] == 1 then
    local st = R.decode(lvl, G.keys[i])
    if not st.fixed[qc] and not st.fixed[qn] and st.asm[qc] ~= st.asm[qn] and row(st.pos[qc]) ~= row(T) and row(st.pos[qn]) == row(T) then
      local k = cfg(st):gsub("  L:.*", "")
      seen[k] = (seen[k] or 0) + 1
      if G.depth[i] < bestd then bestd = G.depth[i]; best = i end
    end
  end
end
for k, v in pairs(seen) do print(k, v) end
if best then
  local path, x = {}, best
  while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
  table.insert(path, 1, 1)
  local last
  for _, s in ipairs(path) do local c = cfg(R.decode(lvl, G.keys[s])); if c ~= last then print(G.depth[s] .. ": " .. c); last = c end end
end
SV.freeGraph(G); require("ffi").C.free(good)
