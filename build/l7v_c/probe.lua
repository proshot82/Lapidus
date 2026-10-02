-- build/l7v_c/probe.lua "<ходы>" [file] — применить ходы (f/H + u r d l), напечатать доску (только в вывод инструмента)
-- и флаги конечного состояния: живое / видимо (по файлу) / скрыто; плюс число живых ходов из него.
local M = dofile("build/l7v_c/lib.lua")
local R = M.R
local def, lvl = M.load(arg[2])
local G, good = M.graph(def, lvl)
local VL = M.V.compute(lvl, G, def, good)
local st = R.newState(lvl)
print(M.show(lvl, st, "start  " .. M.cfg(lvl, st)))
local fin, n, err = M.apply(lvl, st, arg[1] or "", true)
if err then print(err) end
local id = G.index[R.key(fin)]
if not id then print("состояние не в графе?!") return end
local w = R.status(lvl, fin)
print(string.format("после %d ходов: %s | живое=%s | видимо(файл)=%s | знаток=%s | всевед=%s | глубина %d | протечек %d | win=%s",
  n, M.cfg(lvl, fin), tostring(good[id] == 1), tostring(VL.newbie[id]), tostring(VL.expert[id]), tostring(VL.omni[id]), G.depth[id], #w.leaks, tostring(w.win)))
local names = {}
for e = G.eStart.p[id - 1], G.eStart.p[id] - 1 do
  local j = G.edges.p[e]
  local m = G.pmove[j]
  local s2 = R.decode(lvl, G.keys[j])
  local mv
  for k = 1, 8 do local t = R.move(lvl, fin, R.MOVES[k].which, R.MOVES[k].dir); if t and R.key(t) == G.keys[j] then mv = R.moveName(k) break end end
  names[#names + 1] = string.format("%s→%s%s", mv or "?", good[j] == 1 and "жив" or (VL.newbie[j] and "ВИДИМО" or "скрыто"), G.flag[j] == 1 and " WIN" or "")
end
print("ходы отсюда: " .. table.concat(names, "; "))
