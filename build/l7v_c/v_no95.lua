-- Вариант раскладки для проверки роли клетки (9,5): она замурована.
local def = dofile("build/l7c/c_p2b_plus/c7.lua")
def.grid[5] = "###.....###"
def.name = def.name .. " (без (9,5))"
return def
