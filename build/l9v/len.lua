-- build/l9v/len.lua файл.lua Lmin Lmax — тот же уровень при другой длине: ходов, состояний, скрытых (линейка),
-- наобум и ширина коридора кратчайших (solver/strict.lua), двери у пути. Только метрики.
local L = dofile("build/l9v/lib.lua")
local ST = require("solver.strict")
local def = dofile(arg[1])
def.length = { tonumber(arg[2]), tonumber(arg[3]) }
local S = L.load(def)
if not S.G.firstWin then print("НЕРЕШАЕМ n=" .. S.n) return end
local m = L.V.measure(S.G, S.good, S.VL.newbie)
local nwin = 0
for i = 1, S.n do if S.flag[i] == 1 then nwin = nwin + 1 end end
S:free()
local sx = ST.check(def, 3000000)
print(string.format("длина %d–%d: ходов %d, состояний %d, выигрышных %d, скрытых %.1f %%, обезьяна %.3f %%, двери у пути [%s] | наобум %.3f %%, кратчайших %d, ширина %d",
  def.length[1], def.length[2], m.opt, S.n, nwin, m.hiddenPct, m.smart, m.deepList, sx.monkey, sx.shortest, sx.maxWidth))
