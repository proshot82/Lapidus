-- Квартира 7 «Дали напор» — кандидат p2b направления B «лифт с грузом» (build/l7c/b_lift_cargo, 28.09.2026).
-- Ядро «стопка в лифте»: фонтан (напор 2) бьёт из стояка в полу вверх, в узкую шахту; мойка — в стене шахты.
-- Детали лежат по обе стороны фонтана. Лифт кладёт груз стопкой (кто поехал первым, тот и наверху, в шахте не
-- обогнать), а надставка в основании фонтана меняет его резьбу: после неё то, что раньше взлетало, прикручивается
-- внизу. Фонтан в конце закрывает сам Лапидус. Ложный план (§6): «тройник — лифтом к мойке, фонтан потом заглушить
-- сбоку». Тройник в списке объектов стоит раньше мойки: при любой истории он сперва свинчивается со стопкой над
-- собой и только потом закрепляется — выигрышное состояние одно. Итоги — REPORT.md. Решение здесь не пишется.

local UP, RIGHT, DOWN, LEFT = 1, 2, 3, 4
local OPP = { 3, 4, 1, 2 }

local function find(lvl)
  local t = {}
  for q, p in ipairs(lvl.pieces) do
    if p.source then t.src = q elseif p.fixture then t.fix = q end
    if p.tag then t[p.tag] = q end
  end
  return t
end
local function xy(lvl, c) return (c - 1) % lvl.W + 1, math.floor((c - 1) / lvl.W) + 1 end

-- Видимый проигрыш (одной фразой каждое правило):
--  A. деталь лежит на полу там, откуда её не втолкнуть ни в одну клетку струи: путь к столбу по её ряду упирается
--     в стену или закреплённое, либо за ней нет места, откуда толкать (твёрдо или карман, куда Лапидусу не попасть
--     в обход самой детали); с пола деталь поднять нечем;
--  B. фонтана больше нет (из столба вверх ничего не бьёт, Лапидус не в счёт), а тройник ещё не у мойки;
--  C. заглушка и тройник обе в столбе, и заглушка ниже тройника (крышка должна лечь сверху, а стопка в шахте
--     однополосная — поменять местами нельзя).
-- Порядок, в котором детали ещё только поедут, и «ниппель слишком рано» он НЕ помечает — это и есть «ага».
local function visibleLoss(lvl, st)
  local R = require("core.rules")
  local P = lvl.pieces
  local k = find(lvl)
  local sx, sy = xy(lvl, P[k.src].start)
  local fixedAt = {}
  for q = 1, #st.pos do local c = st.pos[q]; if c ~= 0 and st.fixed[q] then fixedAt[c] = true end end
  local function solid(c) return c == 0 or lvl.cell[c] == 1 or fixedAt[c] end
  local function inCol(c) return (xy(lvl, c)) == sx end
  -- основание струи: первая клетка над верхним закреплённым в столбе
  local base = P[k.src].start
  while true do local u = lvl.nb[base][UP]; if u ~= 0 and fixedAt[u] then base = u else break end end
  local firstJet = lvl.nb[base][UP]
  local _, fy = xy(lvl, firstJet)
  -- A
  local function canEnter(c)
    local x = xy(lvl, c)
    local d = (x < sx) and RIGHT or LEFT
    local back = lvl.nb[c][OPP[d]]
    if solid(back) or lvl.cell[back] == 2 then return false end
    -- в клетку толкающего конца надо суметь попасть: заливка от неё в обход самой детали должна дойти до Лапидуса
    local seen, qq, hh, reach = { [back] = true, [c] = true }, { back }, 1, false
    local bodySet = {}
    for _, bc in ipairs(st.body) do bodySet[bc] = true end
    while hh <= #qq and not reach do
      local u = qq[hh]; hh = hh + 1
      if bodySet[u] then reach = true end
      for dd = 1, 4 do
        local v = lvl.nb[u][dd]
        if v ~= 0 and not seen[v] and not solid(v) and lvl.cell[v] ~= 2 then seen[v] = true; qq[#qq + 1] = v end
      end
    end
    if not reach then return false end
    local t = c
    while true do
      t = lvl.nb[t][d]
      if t == 0 or solid(t) then return false end
      local tx, ty = xy(lvl, t)
      if tx == sx then return ty <= fy end
    end
  end
  for q, p in ipairs(P) do
    local c = st.pos[q]
    if p.movable and c ~= 0 and not st.fixed[q] and not inCol(c) and solid(lvl.nb[c][DOWN]) and not canEnter(c) then
      return true
    end
  end
  -- B
  local w = R.water(lvl, st, nil, true)
  local jetUp = false
  for _, L in ipairs(w.leaks) do if L.dir == UP and (xy(lvl, L.cell)) == sx then jetUp = true end end
  local tAtFix = false
  if st.fixed[k.tee] and st.pos[k.tee] ~= 0 then
    for d = 1, 4 do if lvl.nb[st.pos[k.tee]][d] == st.pos[k.fix] then tAtFix = true end end
  end
  if not jetUp and not tAtFix then return true end
  -- C
  local tc, pc = st.pos[k.tee], st.pos[k.plug]
  if tc ~= 0 and inCol(tc) and pc ~= 0 and inCol(pc) and pc > tc then return true end
  return false
end

-- Абляции РОЛИ (фильтры ходов, как в levels/05.lua и levels/06.lua): каждая обязана сделать уровень нерешаемым.
local function colX(lvl) local k = find(lvl); return (xy(lvl, lvl.pieces[k.src].start)) end
-- «Струя не поднимает детали»: запрещено состояние, где незакреплённая деталь стоит в столбе над стояком.
local function noCargo(lvl, st, ns)
  local sx = colX(lvl)
  for q, p in ipairs(lvl.pieces) do
    local c = ns.pos[q]
    if p.movable and c ~= 0 and not ns.fixed[q] and (xy(lvl, c)) == sx then return false end
  end
  return true
end
-- «Заглушка не едет раньше тройника»: запрещено состояние, где заглушка в столбе, а тройника там ещё нет.
local function plugNotFirst(lvl, st, ns)
  local k, sx = find(lvl), colX(lvl)
  local pc, tc = ns.pos[k.plug], ns.pos[k.tee]
  local pIn = pc ~= 0 and (xy(lvl, pc)) == sx
  local tIn = tc ~= 0 and (xy(lvl, tc)) == sx
  return not (pIn and not tIn)
end
-- «Переходник не едет раньше тройника»: запрещено состояние, где переходник в столбе, а тройника там ещё нет.
local function adapterNotBeforeTee(lvl, st, ns)
  local k, sx = find(lvl), colX(lvl)
  local tc, ac = ns.pos[k.tee], ns.pos[k.adp]
  local tIn = tc ~= 0 and (xy(lvl, tc)) == sx
  local aIn = ac ~= 0 and (xy(lvl, ac)) == sx
  return not (aIn and not tIn)
end

return {
  visibleLoss = visibleLoss,
  id = 7, flat = 7, name = "Дали напор",
  length = { 2, 4 }, pressure = 2, tile = "mint",
  stack = { "plug", "adp", "tee" }, -- задуманный порядок стопки сверху вниз (для проверок, в игре не используется)
  target = { moves = { 20, 45 }, states = 1000000, dead = 50, fb = 3 },
  grid = {
    "###########",
    "#####.#####",
    "#####.#####",
    "#####..####",
    "##.....####",
    "##........#",
    "##..#.....#",
    "#####.#####",
    "###########",
  },
  objects = {
    { kind = "source", at = { 6, 8 }, ports = { up = "V" } },
    { kind = "fitting", what = "tee", tag = "tee", at = { 5, 6 }, ports = { up = "N", right = "N", down = "V" } },
    { kind = "fixture", what = "sink", at = { 7, 4 }, ports = { left = "V" } },
    { kind = "fitting", what = "plug", tag = "plug", at = { 7, 7 }, ports = { down = "V" } },
    { kind = "fitting", what = "adapter", tag = "adp", at = { 8, 7 }, ports = { up = "N", down = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 9, 7 }, ports = { up = "N", down = "N" } },
    { kind = "lapidus", cells = { { 4, 5 }, { 5, 5 }, { 6, 5 }, { 7, 5 } }, head = 4 },
  },
  ablations = {
    { name = "без заглушки", remove = "plug" },
    { name = "без ниппеля", remove = "nip" },
    { name = "струя не поднимает детали", filter = noCargo },
    { name = "заглушка не едет раньше тройника", filter = plugNotFirst },
    { name = "переходник не едет раньше тройника", filter = adapterNotBeforeTee },
  },
  texts = {
    request = "Воду дали. До потолка. Мойка не в курсе.",
    hints = {
      "Лифт кладёт груз стопкой: кто поехал первым, тот и наверху. Тройник к мойке поедет последним.",
      "Ваш звонок очень важен для нас. Проверяем, кто у вас едет в лифте первым.",
      "Мастер выехал. Ведро возьмите у соседа сверху.",
    },
  },
}
