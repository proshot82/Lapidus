-- Копия кандидата с разметкой «правила файла + N1» (только подножие, запечатанное ниппелем) — промежуточная мерка.
local def = dofile("build/l7c/c_p2b_plus/c7.lua")
local MK = dofile("build/l7v_c/marks.lua")
local fileRule = def.visibleLoss
def.visibleLoss = function(lvl, st) return fileRule(lvl, st) or MK.N1(lvl, st) end
def.name = def.name .. " (разметка: файл + N1)"
return def
