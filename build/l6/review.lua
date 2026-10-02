-- Разбор кв. 6: какие тупики видны глазом (ниппель на полу/в сливе), какие скрыты;
-- «умная обезьяна», которая не роняет ниппель на пол; узкие места всех выигрышных путей.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1] or "levels/06.lua")
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local nq
for q, p in ipairs(lvl.pieces) do if p.tag == "nip" then nq = q end end
-- ниппель «потерян глазом»: смыт или лежит на стене/полу (не на Лапидусе, не закреплён)
local function nipLost(st)
  local c = st.pos[nq]
  if c == 0 then return true end
  if st.fixed[nq] then return false end
  local below = lvl.nb[c][R.DOWN]
  if below ~= 0 and lvl.cell[below] == R.WALL then return true end
  return false
end
local cnt = { live = 0, lostVisible = 0, hiddenDead = 0, washedLap = 0 }
local states = {}
for i = 1, G.n do
  if G.flag[i] == 2 then cnt.washedLap = cnt.washedLap + 1
  else
    local st = R.decode(lvl, G.keys[i])
    states[i] = st
    if good[i] == 1 then cnt.live = cnt.live + 1
    elseif nipLost(st) then cnt.lostVisible = cnt.lostVisible + 1
    else cnt.hiddenDead = cnt.hiddenDead + 1 end
  end
end
print(string.format("состояний %d: живых %d; тупик «ниппель на полу/смыт» (виден сразу) %d; скрытых тупиков (ниппель ещё на Лапидусе) %d; Лапидус смыт %d",
  G.n, cnt.live, cnt.lostVisible, cnt.hiddenDead, cnt.washedLap))
-- умная обезьяна: из текущего состояния выбирает случайный ход среди тех, что не роняют ниппель на пол (и не смывают)
local function smartMonkey(T)
  local p, ok = { [1] = 1.0 }, 0
  for _ = 1, T do
    local np = {}
    for i, pr in pairs(p) do
      local cand = {}
      for e = G.eStart.p[i - 1], G.eStart.p[i] - 1 do
        local j = G.edges.p[e]
        if G.flag[j] == 1 then cand[#cand + 1] = j
        elseif G.flag[j] ~= 2 and not nipLost(states[j]) then cand[#cand + 1] = j end
      end
      if #cand == 0 then np[i] = (np[i] or 0) + pr
      else
        local share = pr / #cand
        for _, j in ipairs(cand) do
          if G.flag[j] == 1 then ok = ok + share else np[j] = (np[j] or 0) + share end
        end
      end
    end
    p = np
  end
  return ok
end
local opt = G.depth[G.firstWin]
for _, mult in ipairs({ 2, 5, 10 }) do
  local T = mult * opt
  local ok = smartMonkey(T)
  print(string.format("умная обезьяна (не роняет ниппель), %d ходов: успех за попытку %.2f %%, за 1000 ходов с перезапусками %.1f %%", T, 100 * ok, 100 * (1 - (1 - ok) ^ (1000 / T))))
end
-- размер «осмысленного» пространства: состояния, где ниппель на Лапидусе или закреплён
local meaningful, mLive = 0, 0
for i = 1, G.n do if states[i] and not nipLost(states[i]) then meaningful = meaningful + 1; if good[i] == 1 then mLive = mLive + 1 end end end
print(string.format("состояний без видимой потери ниппеля: %d, из них живых %d (%.0f %%)", meaningful, mLive, 100 * mLive / meaningful))
-- узкие места: состояния на кратчайшем пути, без которых выигрыш недостижим (любой длины)
local path, x = {}, G.firstWin
while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
table.insert(path, 1, 1)
local function reachableWithout(ban)
  local seen, q, h = { [1] = true }, { 1 }, 1
  if ban == 1 then return false end
  while h <= #q do
    local u = q[h]; h = h + 1
    if G.flag[u] == 1 then return true end
    for e = G.eStart.p[u - 1], G.eStart.p[u] - 1 do
      local v = G.edges.p[e]
      if v ~= ban and not seen[v] and G.flag[v] ~= 2 then seen[v] = true; q[#q + 1] = v end
    end
  end
  return false
end
local bott = {}
for k = 2, #path - 1 do if not reachableWithout(path[k]) then bott[#bott + 1] = k - 1 end end
print("узкие места (ход, после которого состояние обязательно): " .. (#bott > 0 and table.concat(bott, ", ") or "нет"))
SV.freeGraph(G); require("ffi").C.free(good)
