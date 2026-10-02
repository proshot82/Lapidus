-- build/l8j/width.lua файл.lua — ширина коридора кратчайших решений по глубинам (как solver/strict.lua).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local ST = require("solver.strict")
local def = dofile(arg[1])
local lvl = R.compile(def)
local SV = require("solver.solve")
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
-- кратчайшие: dist от старта = depth; «на пути» — состояния, из которых до победы opt - depth
local opt = G.depth[G.firstWin]
-- обратный BFS расстояний до победы
local n = G.n
local rev = {}
for i = 1, n do for e = G.eStart.p[i-1], G.eStart.p[i]-1 do local j = G.edges.p[e]; rev[j] = rev[j] or {}; rev[j][#rev[j]+1] = i end end
local dw, q, h = {}, {}, 1
for i = 1, n do if G.flag[i] == 1 then dw[i] = 0; q[#q+1] = i end end
while h <= #q do local u = q[h]; h = h + 1; for _, v in ipairs(rev[u] or {}) do if not dw[v] and G.flag[v] ~= 2 then dw[v] = dw[u] + 1; q[#q+1] = v end end end
local w = {}
for i = 1, n do if dw[i] and G.depth[i] + dw[i] == opt then w[G.depth[i]] = (w[G.depth[i]] or 0) + 1 end end
local t = {}
for d = 0, opt do t[#t+1] = tostring(w[d] or 0) end
print("ширина по шагам: " .. table.concat(t, " "))
if arg[2] then
  local d0 = tonumber(arg[2])
  local SYM = { source = "S", fixture = "F", stub = "T", pipe = "=", fitting = "b", porcelain = "p" }
  local frames = {}
  for i = 1, n do if dw[i] and G.depth[i] == d0 and G.depth[i] + dw[i] == opt then
    local s = R.decode(lvl, G.keys[i])
    local rows = {}
    for y = 1, lvl.H do rows[y] = {} for x = 1, lvl.W do local c = lvl.cell[(y-1)*lvl.W+x]; rows[y][x] = c == 1 and "#" or (c == 2 and "~" or ".") end end
    for q, pp in ipairs(lvl.pieces) do if s.pos[q] ~= 0 then local x, y = R.xy(lvl, s.pos[q]); rows[y][x] = SYM[pp.kind] end end
    for k, c in ipairs(s.body) do local x, y = R.xy(lvl, c); rows[y][x] = (k == #s.body) and "H" or ((k == 1) and "f" or "o") end
    local out = {}
    for y = 1, lvl.H do out[y] = table.concat(rows[y]) end
    frames[#frames+1] = out
  end end
  for y = 1, lvl.H do local parts = {} for _, f in ipairs(frames) do parts[#parts+1] = f[y] .. "  " end print(table.concat(parts)) end
end
