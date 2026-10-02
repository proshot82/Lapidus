-- build/l10v/var.lua — варианты o34 без смены ядра (только старт Лапидуса и ниппеля) для вопроса «структурна ли прогулка 9».
-- luajit build/l6b/check.lua build/l10v/var.lua  с переменной окружения VAR=A|B|C. Раскладка o34 не меняется.
local d = dofile("build/l10a/o34.lua")
local v = os.getenv("VAR") or "A"
local function set(tag, x, y) for _, o in ipairs(d.objects) do if o.tag == tag then o.at = { x, y } end end end
local function lap(cells, head) for _, o in ipairs(d.objects) do if o.kind == "lapidus" then o.cells = cells; o.head = head end end end
if v == "A" then set("nip", 8, 5); lap({ { 9, 5 }, { 10, 5 } }, 2)        -- Лапидус справа от ниппеля, голова к унитазу
elseif v == "B" then set("nip", 7, 5); lap({ { 9, 5 }, { 8, 5 } }, 2)     -- справа от ниппеля, голова к ниппелю
elseif v == "C" then lap({ { 8, 2 }, { 9, 2 } }, 2)                        -- Лапидус стартует на верхнем ряду склада
elseif v == "D" then lap({ { 10, 3 }, { 10, 2 } }, 2)                      -- стартует справа на полке
end
d.ablations = d.ablations
return d
