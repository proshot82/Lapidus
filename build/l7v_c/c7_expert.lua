-- Копия кандидата с разметкой по мерке ЗНАТОКА слепого скептика: новичок-скептик + X1 (неверный порядок очереди
-- в коридоре); общая линейка tools/vislib.lua добавляет своё (деталь не на финальном месте, «любой ход вскрывает»)
-- в строке «знаток (для сведения)» check.lua. Правила — build/l7v_c/marks.lua. Решение здесь не пишется.
local def = dofile("build/l7c/c_p2b_plus/c7.lua")
local MK = dofile("build/l7v_c/marks.lua")
local fileRule = def.visibleLoss
def.visibleLoss = function(lvl, st) return fileRule(lvl, st) or MK.N1(lvl, st) or MK.N2(lvl, st) or MK.X1(lvl, st) end
def.name = def.name .. " (разметка: знаток-скептик)"
return def
