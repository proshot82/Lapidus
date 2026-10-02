-- Вариант раскладки для проверки роли жёлоба: клетка (8,6) замурована, Лапидус начинает (9,6),(10,6),(10,7).
local def = dofile("build/l7c/c_p2b_plus/c7.lua")
def.grid[6] = "###...##..#"
for _, o in ipairs(def.objects) do if o.kind == "lapidus" then o.cells = { { 9, 6 }, { 10, 6 }, { 10, 7 } }; o.head = 3 end end
def.name = def.name .. " (без жёлоба)"
return def
