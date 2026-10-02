-- build/l3c/widthshow.lua файл.lua шаг — кадры состояний кратчайших решений на данном шаге (только вывод инструмента)
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local ST = require("solver.strict")
local def = dofile(arg[1])
local lvl = R.compile(def)
-- граф с состояниями
local s0 = R.newState(lvl)
local ids, st, succ, win, dist, order = { [R.key(s0)] = 1 }, { s0 }, {}, {}, { 0 }, { 1 }
local head = 1
while head <= #order do
  local i = order[head]; head = head + 1
  local s = st[i]
  win[i] = (not s.dead) and R.isWin(lvl, s)
  local out = {}
  if not win[i] and not s.dead then
    for m = 1, 8 do
      local mv = R.MOVES[m]
      local ns = R.move(lvl, s, mv.which, mv.dir)
      if ns then
        local k = R.key(ns); local j = ids[k]
        if not j then j = #dist + 1; ids[k], st[j], dist[j] = j, ns, dist[i] + 1; order[#order + 1] = j end
        out[#out + 1] = j
      end
    end
  end
  succ[i] = out
end
local opt; for i = 1, #dist do if win[i] and (not opt or dist[i] < opt) then opt = dist[i] end end
local on = {}
for i = 1, #dist do if win[i] and dist[i] == opt then on[i] = true end end
for i = #dist, 1, -1 do if not on[i] and dist[i] < opt then for _, j in ipairs(succ[i]) do if on[j] and dist[j] == dist[i] + 1 then on[i] = true; break end end end end
local want = tonumber(arg[2])
local frames = {}
for i = 1, #dist do if on[i] and dist[i] == want then
  local s = st[i]
  local rows = {}
  for y = 1, lvl.H do rows[y] = {} for x = 1, lvl.W do local c = lvl.cell[(y-1)*lvl.W+x]; rows[y][x] = c == 1 and "#" or (c == 2 and "~" or ".") end end
  for q, p in ipairs(lvl.pieces) do if s.pos[q] ~= 0 then local x, y = R.xy(lvl, s.pos[q]); rows[y][x] = p.porcelain and "p" or (p.source and "S" or "F") end end
  for k, c in ipairs(s.body) do local x, y = R.xy(lvl, c); rows[y][x] = (k == #s.body) and "H" or (k == 1 and "f" or "o") end
  local out = {}
  for y = 1, lvl.H do out[y] = table.concat(rows[y]) end
  frames[#frames + 1] = out
end end
for y = 1, lvl.H do local parts = {} for _, f in ipairs(frames) do parts[#parts + 1] = f[y] .. "  " end print(table.concat(parts)) end
