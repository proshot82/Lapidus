-- build/l7v_d/mech.lua — честность правил: мини-примеры движка на поведение, которого нет на карточке кв. 7
-- (art/screens2.py pan_pressure: столб держит деталь над верхушкой; струя вбок толкает деталь; деталь, вошедшая
-- в первую клетку струи, прикручивается и глушит её). Проверяем, что реально делает ядро.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local function L(grid, objects, len, pressure) return R.compile({ grid = grid, objects = objects, length = len or { 2, 5 }, pressure = pressure or 3 }) end
local function lap(cells, head) return { kind = "lapidus", cells = cells, head = head } end
local function body(lvl, st) local t = {} for _, c in ipairs(st.body) do t[#t + 1] = string.format("(%d,%d)", R.xy(lvl, c)) end return table.concat(t, " ") end
local function pos(lvl, st, q) if st.pos[q] == 0 then return "смыто" end local x, y = R.xy(lvl, st.pos[q]) return string.format("(%d,%d)", x, y) .. (st.fixed[q] and "F" or "") end

print("1. Неприкрученный Лапидус в столбе фонтана: поднимает ли столб его целиком, и что если над одной клеткой потолок")
do
  local g = { "#######", "#.....#", "#.....#", "#.....#", "#.....#", "#.....#", "#######" }
  local lvl = L(g, { { kind = "source", at = { 3, 6 }, ports = { up = "N" } }, lap({ { 4, 5 }, { 3, 5 } }, 2) })
  print("   без потолка: тело после устаканивания " .. body(lvl, R.newState(lvl)) .. "  (столб 3 клетки: (3,5),(3,4),(3,3))")
  local g2 = { "#######", "#.....#", "#.....#", "####..#", "#.....#", "#.....#", "#######" }
  local lvl2 = L(g2, { { kind = "source", at = { 5, 6 }, ports = { up = "N" } }, lap({ { 4, 5 }, { 5, 5 } }, 2) })
  print("   с потолком над одной клеткой: тело " .. body(lvl2, R.newState(lvl2)) .. "  (не поднят — «пробка»)")
end
print("2. Проходит ли струя сквозь неприкрученного Лапидуса (держит ли она деталь над ним)")
do
  local g = { "#######", "#.....#", "#.....#", "####..#", "#.....#", "#.....#", "#######" }
  local lvl = L(g, { { kind = "source", at = { 5, 6 }, ports = { up = "N" } }, { kind = "fitting", at = { 5, 2 }, ports = { left = "N" } }, lap({ { 4, 5 }, { 5, 5 } }, 2) })
  local s = R.newState(lvl)
  print("   деталь, брошенная сверху на столб с Лапидусом в первой клетке: " .. pos(lvl, s, 2) .. " (столб (5,5),(5,4),(5,3); верхушка+1 = (5,2))")
end
print("3. Деталь ПОД Лапидусом в столбе: удерживается ли (струя не может её толкнуть сквозь тело)")
do
  local g = { "#######", "#.....#", "#.....#", "####..#", "#.....#", "#.....#", "#######" }
  -- Лапидус (4,4)-(5,4) не поднимается (потолок над (4,4)); деталь без подходящей резьбы кладём в (5,5) — первую клетку
  local lvl = L(g, { { kind = "source", at = { 5, 6 }, ports = { up = "N" } }, { kind = "fitting", at = { 5, 5 }, ports = { left = "N" } }, lap({ { 4, 4 }, { 5, 4 } }, 2) })
  local s = R.newState(lvl)
  print("   деталь в первой клетке под телом: " .. pos(lvl, s, 2) .. ", тело " .. body(lvl, s))
end
print("4. Прикрученный Лапидус перекрывает струю (струя не доходит до того, что за ним)")
do
  local g = { "##########", "#........#", "#........#", "##########" }
  local lvl = L(g, { { kind = "source", at = { 2, 3 }, ports = { right = "N" } }, { kind = "stub", at = { 4, 2 }, ports = { down = "N" } },
    { kind = "porcelain", at = { 6, 3 } }, lap({ { 5, 3 }, { 4, 3 } }, 2) })
  local s = R.newState(lvl)
  print("   голова прикручена к отводу над струёй, тело в струе; мыло за телом: " .. pos(lvl, s, 3) .. " (без Лапидуса улетело бы на (5,3)→за пределы)")
  local lvl2 = L(g, { { kind = "source", at = { 2, 3 }, ports = { right = "N" } }, { kind = "porcelain", at = { 6, 3 } }, lap({ { 5, 3 }, { 4, 3 } }, 2) })
  local s2 = R.newState(lvl2)
  print("   тот же, но Лапидус не прикручен: мыло " .. pos(lvl2, s2, 2) .. ", тело " .. body(lvl2, s2))
end
print("5. Струя вбок толкает неприкрученного Лапидуса, затем он падает; резьба на лету прикручивает ноги")
do
  local g = { "#########", "#.......#", "#.......#", "#.......#", "####....#", "#########" }
  local lvl = L(g, { { kind = "source", at = { 2, 4 }, ports = { right = "N" } }, { kind = "fixture", at = { 4, 5 }, ports = { up = "V" } },
    lap({ { 3, 4 }, { 3, 3 } }, 2) })
  local s = R.newState(lvl)
  local w = R.status(lvl, s)
  print("   ноги в первой клетке струи, тело вверх: тело " .. body(lvl, s) .. "; ноги прикручены к ванне: " .. tostring(w.heelQ ~= nil))
end
print("6. Порядок в шаге: струи раньше гравитации (деталь, упавшая в клетку струи вбок, сначала толкается, потом падает)")
do
  local g = { "########", "#......#", "#......#", "#......#", "###....#", "########" }
  local lvl = L(g, { { kind = "source", at = { 2, 4 }, ports = { right = "N" } }, { kind = "porcelain", at = { 3, 2 } }, lap({ { 6, 2 }, { 6, 3 } }, 2) }, { 2, 5 }, 1)
  local s = R.newState(lvl)
  print("   мыло падает по столбцу 3 в струю длиной 1 у пола (3,4): итог " .. pos(lvl, s, 2) .. " (если бы гравитация была раньше струи — упало бы и толкнулось иначе)")
end
print("7. Стоит ли Лапидус на детали, которую держит столб (опора через висящую деталь)")
do
  local g = { "#######", "#.....#", "#.....#", "#.....#", "#.....#", "#.....#", "#######" }
  local lvl = L(g, { { kind = "source", at = { 3, 6 }, ports = { up = "N" } }, { kind = "fitting", at = { 3, 2 }, ports = { left = "N" } }, lap({ { 4, 2 }, { 5, 2 } }, 2) })
  local s = R.newState(lvl)
  print("   деталь над верхушкой " .. pos(lvl, s, 2) .. "; Лапидус на ней " .. body(lvl, s) .. " (если бы не стоял — упал бы на пол)")
end
print("8. Столб толкает деталь вверх сквозь Лапидуса? (деталь в столбе, Лапидус над ней в столбе, неприкручен, с потолком)")
do
  local g = { "#######", "#.....#", "#.....#", "####..#", "#.....#", "#.....#", "#######" }
  local lvl = L(g, { { kind = "source", at = { 5, 6 }, ports = { up = "N" } }, { kind = "fitting", at = { 5, 5 }, ports = { left = "N" } }, lap({ { 4, 4 }, { 5, 4 } }, 2) })
  local s = R.newState(lvl)
  print("   деталь " .. pos(lvl, s, 2) .. " (остаётся в основании — Лапидус её держит)")
end
