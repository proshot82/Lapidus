-- build/l3v/v_norule1.lua — копия кв. 3 с альтернативной разметкой видимого проигрыша (скептик, 29.09).
-- только правило (2) автора, без правила (1) «любое заклинившее мыло»
local def = dofile("levels/03.lua")
local VR = dofile("build/l3v/visrules.lua")
def.visibleLoss = VR.make({ rule1 = false, sealed = false })
def.name = def.name .. " [norule1]"
return def
