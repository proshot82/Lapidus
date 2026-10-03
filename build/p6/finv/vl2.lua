-- правило уровня, суженное: все детали закреплены, а Лапидус целиком вне коридора (вход заткнут)
local d = dofile("build/p6/fin/final.lua")
local old = d.visibleLoss
d.visibleLoss = function(lvl, st)
  if not old(lvl, st) then return false end
  for _, b in ipairs(st.body) do local y = math.floor((b - 1) / lvl.W) + 1; local x = (b - 1) % lvl.W + 1; if y == 6 and x <= 9 then return false end end
  return true
end
return d
