-- build/l4v2/spshow.lua — ТОЛЬКО ДЛЯ ТЕРМИНАЛА: кадры состояний на кратчайших путях на шагах arg[2..] (для разбора ширины).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local ES, E, flag = G.eStart.p, G.edges.p, G.flag
local opt = G.depth[G.firstWin]
local rv, cnt = {}, {}
local toWin = {}
-- простая обратная BFS
local preds = {}
for i = 1, G.n do for e = ES[i - 1], ES[i] - 1 do local j = E[e]; preds[j] = preds[j] or {}; table.insert(preds[j], i) end end
local q, h = {}, 1
for i = 1, G.n do if flag[i] == 1 then toWin[i] = 0; q[#q + 1] = i end end
while h <= #q do local j = q[h]; h = h + 1; for _, i in ipairs(preds[j] or {}) do if toWin[i] == nil and flag[i] == 0 then toWin[i] = toWin[j] + 1; q[#q + 1] = i end end end
local SYM = { source = "S", fixture = "F", stub = "T", pipe = "=", fitting = "b" }
local function show(s)
  local rows = {}
  for y = 1, lvl.H do rows[y] = {} for x = 1, lvl.W do local c = lvl.cell[(y-1)*lvl.W+x]; rows[y][x] = c == 1 and "#" or "." end end
  for qq, pp in ipairs(lvl.pieces) do if s.pos[qq] ~= 0 then local x, y = R.xy(lvl, s.pos[qq]); local ch = SYM[pp.kind]; if pp.movable then ch = (pp.what == "coupling") and (s.fixed[qq] and "C" or "c") or (s.fixed[qq] and "N" or "n") end; rows[y][x] = ch end end
  for i, c in ipairs(s.body) do local x, y = R.xy(lvl, c); rows[y][x] = (i == #s.body) and "H" or ((i == 1) and "f" or "o") end
  local out = {}; for y = 1, lvl.H do out[y] = table.concat(rows[y]) end; return out
end
for a = 2, #arg do
  local d = tonumber(arg[a])
  local fr = {}
  for i = 1, G.n do if G.depth[i] == d and toWin[i] and d + toWin[i] == opt then fr[#fr + 1] = show(R.decode(lvl, G.keys[i])) end end
  print("шаг " .. d)
  for y = 1, lvl.H do local t = {} for _, f in ipairs(fr) do t[#t + 1] = f[y] .. "  " end print(table.concat(t)) end
end
