-- build/l3v/v_alcove.lua — копия кв. 3 с альтернативной разметкой видимого проигрыша (скептик, 29.09).
-- правило автора + «запечатано» (ниша): мыло перед нишей (2,6) бесполезно на вид
local def = dofile("levels/03.lua")
local VR = dofile("build/l3v/visrules.lua")
def.visibleLoss = VR.make({ rule1 = true, sealed = true })
def.name = def.name .. " [alcove]"
return def
