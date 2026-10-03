-- сколько состояний помечает правило уровня, из них живых / скрытых без правила
local L = dofile("build/l10v/lib.lua")
local def = dofile("build/p6/fin/final.lua")
local S = L.load(def)
local liveHit, deadHit, wins = 0, 0, 0
for i = 1, S.n do if S.flag[i] == 0 then
  local s = S:st(i)
  if def.visibleLoss(S.lvl, s) then if S:live(i) then liveHit = liveHit + 1 else deadHit = deadHit + 1 end end
end end
print("правило: живых помечено", liveHit, "мёртвых", deadHit)
-- классы мёртвых по правилу: где Лапидус (сверху/в коридоре) и куда смотрит голова
local C = {}
for i = 1, S.n do if S.flag[i] == 0 and not S:live(i) then local s = S:st(i)
  if def.visibleLoss(S.lvl, s) then
    local inC, up = 0, 0
    for _, c in ipairs(s.body) do local x, y = L.R.xy(S.lvl, c); if y == 6 and x < 10 then inC = inC + 1 else up = up + 1 end end
    local k = S:fixedSig(s) .. " | тело в коридоре " .. inC .. "/" .. #s.body
    C[k] = (C[k] or 0) + 1 end end end
for k, v in pairs(C) do print(v, k) end
