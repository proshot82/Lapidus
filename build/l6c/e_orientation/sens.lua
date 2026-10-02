-- sens.lua файл.lua — чувствительность к видимому проигрышу: метрики с vis_wide.lua (без решений).
package.path = "./?.lua;" .. package.path
local GT = dofile("build/l6c/e_orientation/gates.lua")
local def = dofile(arg[1])
def.visibleLoss = dofile("build/l6c/e_orientation/vis_wide.lua")
local r = GT.eval(def, { noabl = true, nostrict = true })
print("с заведомо широким видимым проигрышем: " .. r.line)
