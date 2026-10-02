-- отладка мерки (в): что даёт переворот мёртвого состояния. Без ходов решения.
package.path = "./?.lua;" .. package.path
arg = { "build/l2e/k6.lua" }
local real = print; print = function() end
local P = dofile("build/l2v3/probe.lua"); print = real
local R = require("core.rules"); local lvl = R.compile(dofile(arg[1]))
local W = lvl.W
local cnt = 0
for i in pairs(P.dead) do
  local s = R.clone(P.sts[i]); local b, m = s.body, #s.body
  for k = 1, math.floor(m / 2) do b[k], b[m + 1 - k] = b[m + 1 - k], b[k] end
  R.settle(lvl, s)
  if cnt < 3 then
    local t = {}; for _, c in ipairs(P.sts[i].body) do t[#t+1] = string.format("(%d,%d)", (c-1)%W+1, math.floor((c-1)/W)+1) end
    local t2 = {}; for _, c in ipairs(s.body) do t2[#t2+1] = string.format("(%d,%d)", (c-1)%W+1, math.floor((c-1)/W)+1) end
    print(table.concat(t, ""), "->", table.concat(t2, ""), "win?", R.isWin(lvl, s))
  end
  cnt = cnt + 1
end
-- независимая BFS из перевёрнутого
local function bfsWin(s0)
  local seen, q, h = { [R.key(s0)] = true }, { s0 }, 1
  while h <= #q do local s = q[h]; h = h + 1
    if not s.dead then if R.isWin(lvl, s) then return true, #q end
      for m = 1, 8 do local ns = R.move(lvl, s, R.MOVES[m].which, R.MOVES[m].dir)
        if ns then local k = R.key(ns); if not seen[k] then seen[k] = true; q[#q + 1] = ns end end end end end
  return false, #q
end
local yes, no = 0, 0
for i in pairs(P.dead) do
  local s = R.clone(P.sts[i]); local b, m = s.body, #s.body
  for k = 1, math.floor(m / 2) do b[k], b[m + 1 - k] = b[m + 1 - k], b[k] end
  R.settle(lvl, s)
  local j = nil
  local w, n = bfsWin(s)
  if w then yes = yes + 1 else no = no + 1 end
end
print("перевёрнутые мёртвые: живых", yes, "мёртвых", no)
