-- build/l4d/trace.lua файл.lua x1 y1 [F] x2 y2 [F] — найти живое состояние с муфтой в (x1,y1) и ниппелем в (x2,y2)
-- (F — закреплена) и напечатать цепочку конфигураций деталей от старта (только в терминал).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local a = {}
for i = 2, #arg do a[#a+1] = arg[i] end
local qc, qn
for q, p in ipairs(lvl.pieces) do if p.what == "coupling" then qc = q elseif p.movable then qn = q end end
local function parse(k) local x, y = tonumber(a[k]), tonumber(a[k+1]); local f = a[k+2] == "F"; return R.idx(lvl, x, y), f, f and k+3 or k+2 end
local c1, f1, k = parse(1); local c2, f2 = parse(k)
local function cfg(st)
  local t = {}
  for q, p in ipairs(lvl.pieces) do if p.movable then local x, y = R.xy(lvl, st.pos[q]); t[#t+1] = string.format("%s(%d,%d)%s", p.tag, x, y, st.fixed[q] and "F" or "") end end
  local b = st.body; local hx, hy = R.xy(lvl, b[#b]); local fx, fy = R.xy(lvl, b[1])
  return table.concat(t, " ") .. string.format("  L:ноги(%d,%d)голова(%d,%d)", fx, fy, hx, hy)
end
for i = 1, G.n do
  if G.flag[i] ~= 2 and good[i] == 1 then
    local st = R.decode(lvl, G.keys[i])
    if st.pos[qc] == c1 and st.pos[qn] == c2 and (st.fixed[qc] or false) == f1 and (st.fixed[qn] or false) == f2 then
      local path, x = {}, i
      while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
      table.insert(path, 1, 1)
      local last
      for _, s in ipairs(path) do local c = cfg(R.decode(lvl, G.keys[s])); if c ~= last then print(G.depth[s] .. ": " .. c); last = c end end
      break
    end
  end
end
SV.freeGraph(G); require("ffi").C.free(good)
