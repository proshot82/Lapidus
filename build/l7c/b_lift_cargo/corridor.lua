-- corridor.lua файл.lua шаг — все состояния коридора кратчайших на данном шаге (кадры только для вывода инструмента).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local step = tonumber(arg[2])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local n = G.n
local E, ES = G.edges.p, G.eStart.p
local rev = {}
for i = 1, n do for e = ES[i - 1], ES[i] - 1 do local j = E[e]; local t = rev[j]; if not t then t = {}; rev[j] = t end; t[#t + 1] = i end end
local dw, q, h = {}, {}, 1
for i = 1, n do if G.flag[i] == 1 then dw[i] = 0; q[#q + 1] = i end end
while h <= #q do local u = q[h]; h = h + 1; for _, p in ipairs(rev[u] or {}) do if dw[p] == nil and G.flag[p] ~= 2 then dw[p] = dw[u] + 1; q[#q + 1] = p end end end
local opt = G.depth[G.firstWin]
local SYM = { source = "S", fixture = "F", stub = "T", pipe = "=", fitting = "b", porcelain = "P" }
local function show(s)
  local rows = {}
  for y = 1, lvl.H do rows[y] = {} for x = 1, lvl.W do local c = lvl.cell[(y-1)*lvl.W+x]; rows[y][x] = c == 1 and "#" or (c == 2 and "~" or ".") end end
  for qq, pp in ipairs(lvl.pieces) do if s.pos[qq] ~= 0 then local x, y = R.xy(lvl, s.pos[qq]); local ch = (pp.tag and pp.tag:sub(1,1)) or SYM[pp.kind]; if pp.movable then ch = s.fixed[qq] and ch:upper() or ch:lower() else ch = SYM[pp.kind] end; rows[y][x] = ch end end
  for i, c in ipairs(s.body) do local x, y = R.xy(lvl, c); rows[y][x] = (i == #s.body) and "H" or ((i == 1) and "f" or "o") end
  local out = {}
  for y = 1, lvl.H do out[#out+1] = table.concat(rows[y]) end
  return out
end
local frames = {}
for i = 1, n do if dw[i] and G.depth[i] == step and G.depth[i] + dw[i] == opt then frames[#frames+1] = show(R.decode(lvl, G.keys[i])) end end
for line = 1, lvl.H do local parts = {} for _, f in ipairs(frames) do parts[#parts+1] = f[line] .. "  " end print(table.concat(parts)) end
SV.freeGraph(G)
