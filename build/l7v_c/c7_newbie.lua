-- Копия кандидата build/l7c/c_p2b_plus/c7.lua с разметкой видимого проигрыша по САМОЙ ШИРОКОЙ ещё честной мерке
-- новичка слепого скептика: правила файла + N1 (подножие запечатано ниппелем) + N2 (карман запечатан деталями).
-- Правила — build/l7v_c/marks.lua. Решение здесь не пишется.
local def = dofile("build/l7c/c_p2b_plus/c7.lua")
local MK = dofile("build/l7v_c/marks.lua")
local fileRule = def.visibleLoss
def.visibleLoss = function(lvl, st) return fileRule(lvl, st) or MK.N1(lvl, st) or MK.N2(lvl, st) end
def.name = def.name .. " (разметка: новичок-скептик)"
return def
