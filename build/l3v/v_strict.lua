-- build/l3v/v_strict.lua — копия кв. 3 с альтернативной разметкой видимого проигрыша (скептик, 29.09).
-- правило (2) + «запечатано», без правила (1): последовательная мерка новичка
local def = dofile("levels/03.lua")
local VR = dofile("build/l3v/visrules.lua")
def.visibleLoss = VR.make({ rule1 = false, sealed = true })
def.name = def.name .. " [strict]"
return def
