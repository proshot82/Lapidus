-- build/l10v/risk.lua файл.lua — риск по кратчайшим путям (любой уровень): из состояний всех кратчайших путей — доля ходов
-- в проигрыш (скрытый / видимый / смыт), число кратчайших путей, шаги с дверями на всех путях. Только метрики.
local L = dofile("build/l10v/lib.lua")
local S = L.load(arg[1])
local opt, sp = S:opt(), S:onShortest()
local mv, hd, vs, steps = 0, 0, 0, {}
for i in pairs(sp) do if S.flag[i] == 0 then
  for e = S.ES[i-1], S.ES[i]-1 do local j = S.E[e]; mv = mv + 1
    if S.flag[j] == 2 then vs = vs + 1
    elseif S.flag[j] == 0 and not S:live(j) then if S.VL.newbie[j] then vs = vs + 1 else hd = hd + 1; steps[S.G.depth[i]] = true end end end end end
local t = {}
for d = 0, opt - 1 do if steps[d] then t[#t+1] = tostring(d) end end
print(string.format("%s: ходов %d; ходов из состояний кратчайших путей %d; в проигрыш %d (%.1f %%), из них скрытый %d (%.1f %%); шаги с дверями [%s]",
  arg[1], opt, mv, hd + vs, 100 * (hd + vs) / mv, hd, 100 * hd / mv, table.concat(t, ",")))
S:free()
