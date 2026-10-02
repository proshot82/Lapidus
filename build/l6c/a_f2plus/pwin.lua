-- build/l6c/a_f2plus/pwin.lua файл.lua — вероятность выигрыша умной обезьяны без лимита времени
-- (поглощающая цепь: выигрыш / скрытый тупик), по шагам кратчайшего пути. Только числа.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local st = {}
local function S(i) st[i] = st[i] or R.decode(lvl, G.keys[i]); return st[i] end
local function lost(s)
  for q, p in ipairs(lvl.pieces) do if p.movable and s.pos[q] == 0 then return true end end
  return def.visibleLoss and def.visibleLoss(lvl, s) or false
end
local cand = {}
for i = 1, G.n do
  if G.flag[i] == 0 and good[i] == 1 then
    local c = {}
    for e = G.eStart.p[i - 1], G.eStart.p[i] - 1 do
      local j = G.edges.p[e]
      if G.flag[j] == 1 or (G.flag[j] ~= 2 and not lost(S(j))) then c[#c + 1] = j end
    end
    cand[i] = c
  end
end
local P = {}
for i = 1, G.n do if G.flag[i] == 1 then P[i] = 1 elseif good[i] == 1 then P[i] = 0 else P[i] = 0 end end
for it = 1, 3000 do
  local delta = 0
  for i, c in pairs(cand) do
    if #c > 0 then
      local s = 0
      for _, j in ipairs(c) do s = s + (P[j] or 0) end
      s = s / #c
      local d = math.abs(s - P[i]); if d > delta then delta = d end
      P[i] = s
    end
  end
  if delta < 1e-10 then break end
end
local path, x = {}, G.firstWin
while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
table.insert(path, 1, 1)
local t = {}
for k, s in ipairs(path) do t[#t + 1] = string.format("%d:%.1f", k - 1, 100 * P[s]) end
print("P(выигрыш) по шагам пути, %: " .. table.concat(t, " "))
SV.freeGraph(G); require("ffi").C.free(good)
