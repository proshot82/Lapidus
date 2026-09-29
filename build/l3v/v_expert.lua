-- build/l3v/v_expert.lua — копия кв. 3 с альтернативной разметкой видимого проигрыша (скептик, 29.09).
-- знаток: плюс «подставка потеряна, второе мыло не поймать»
local def = dofile("levels/03.lua")
local VR = dofile("build/l3v/visrules.lua")
def.visibleLoss = VR.make({ rule1 = true, sealed = true, expert = true })
def.name = def.name .. " [expert]"
return def
