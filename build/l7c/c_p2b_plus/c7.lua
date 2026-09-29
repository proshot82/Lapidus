-- Квартира 7 «Дали напор» — кандидат c7 направления C «p2b+» (build/l7c/c_p2b_plus, 29.09.2026).
-- Ядро прежнее: фонтан (напор 2) бьёт из стояка в полу вверх, в узкую шахту; мойка — в стене шахты; лифт кладёт груз
-- стопкой (кто поехал первым, тот и наверху, в шахте не обогнать); ниппель в основании меняет резьбу фонтана и
-- поднимает стопку на клетку; фонтан в конце закрывает сам Лапидус. Переходника-заполнителя больше нет: три детали,
-- у каждой своя работа — тройник ведёт воду в мойку, заглушка закрывает его верх, ниппель в основании даёт Лапидусу
-- нужную резьбу снизу.
-- Раскладка: справа у фонтана очередь «заглушка, пустое место, ниппель» под глухой крышей, над пустым местом —
-- жёлоб; тройник — в комнатке слева за фонтаном, между ними у пола — глухая стенка. Ложный план: толкнуть очередь в
-- лифт сразу — ведь заглушка должна ехать первой. Тогда ниппель занимает пустое место, и тройнику в очереди
-- встать некуда; видно это становится только через несколько ходов.
-- «Ага» (подсказка №1): лифт кладёт груз стопкой — кто поехал первым, тот и наверху; тройник к мойке поедет последним,
-- но в очередь встанет заранее.
-- Видимый проигрыш — по мерке новичка (docs/DESIGN.md §7); мерка знатока — для сведения (LOG.md).
-- Итоги и проверки — LOG.md. Решение здесь не пишется.

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

-- Видимый проигрыш, мерка НОВИЧКА (игрок знает правила и карточки, но не решение). Одной фразой каждое правило:
--  A. деталь (или свинченная пара) больше никогда не попадёт в столб фонтана, а поднять её больше нечему: её можно
--     только толкать вдоль ряда (с падением с уступов), и путь к столбу упирается в стену или закреплённое, либо
--     толкать не из чего — клетка для толкающего конца там, куда Лапидусу не пройти в обход самой детали
--     (угол, зажата, запечатана); подвижные детали на пути не в счёт;
--  B. выход стояка навсегда закрыт — фонтана вверх больше нет (Лапидус не в счёт), а тройник не у мойки;
--  D. тройник навсегда прикручен не у мойки — его выход смотрит в стену;
--  E. тройник прикручен у мойки, а заглушки на нём нет — его верх навсегда открыт в глухую шахту.
-- Неверный порядок деталей, неверная пара и деталь «не на своём месте» новичку не видны — это и есть «ага».
local function visibleLoss(lvl, st)
  local R = require("core.rules")
  local P = lvl.pieces
  local k = find(lvl)
  local sx = xy(lvl, P[k.src].start)
  local fixC = P[k.fix].start
  local fixedAt, pieceAt = {}, {}
  for q = 1, #st.pos do local c = st.pos[q]; if c ~= 0 then pieceAt[c] = q; if st.fixed[q] then fixedAt[c] = true end end end
  local function wall(c) return c == 0 or lvl.cell[c] == 1 end
  local function solid(c) return wall(c) or fixedAt[c] end
  local function inCol(c) return c ~= 0 and (xy(lvl, c)) == sx end
  local tq, pq = k.tee, k.plug
  local tc, pc = st.pos[tq], st.pos[pq]
  local teeAtSink = false
  if st.fixed[tq] and tc ~= 0 then for d = 1, 4 do if lvl.nb[tc][d] == fixC then teeAtSink = true end end end
  -- D, E
  if st.fixed[tq] and not teeAtSink then return true end
  if teeAtSink and not (pc == lvl.nb[tc][UP] and st.fixed[pq]) then return true end
  -- B
  local w = R.water(lvl, st, nil, true)
  local jetUp = false
  for _, L in ipairs(w.leaks) do if L.dir == UP and (xy(lvl, L.cell)) == sx then jetUp = true end end
  if not jetUp and not teeAtSink then return true end
  -- A
  local body = {}
  for _, b in ipairs(st.body) do body[b] = true end
  local function reach(from, avoid)
    if solid(from) or avoid[from] then return false end
    local seen, q, h = { [from] = true }, { from }, 1
    while h <= #q do
      local u = q[h]; h = h + 1
      if body[u] then return true end
      for d = 1, 4 do
        local v = lvl.nb[u][d]
        if v ~= 0 and not seen[v] and not solid(v) and not avoid[v] then seen[v] = true; q[#q + 1] = v end
      end
    end
    return false
  end
  local function keyOf(cells) local t = {}; for i, c in ipairs(cells) do t[i] = c end; table.sort(t); return table.concat(t, ",") end
  local function canEnter(q0)
    local mem, selfSet, c0 = {}, {}, {}
    for r = 1, #st.pos do if st.pos[r] ~= 0 and not st.fixed[r] and st.asm[r] == st.asm[q0] then mem[#mem + 1] = r; selfSet[r] = true end end
    for i, r in ipairs(mem) do c0[i] = st.pos[r] end
    local function fall(cells)
      while true do
        local down = {}
        for i, c in ipairs(cells) do
          local b = lvl.nb[c][DOWN]
          if b == 0 or solid(b) then return cells end
          if pieceAt[b] and not selfSet[pieceAt[b]] and not body[b] then return cells end
          down[i] = b
        end
        cells = down
      end
    end
    local seen, qq, h = { [keyOf(c0)] = true }, { c0 }, 1
    while h <= #qq do
      local cells = qq[h]; h = h + 1
      local occ = {}
      for _, c in ipairs(cells) do occ[c] = true end
      for _, d in ipairs({ LEFT, RIGHT }) do
        local moved = {}
        for i, c in ipairs(cells) do local t = lvl.nb[c][d]; if t == 0 or solid(t) then moved = nil; break end; moved[i] = t end
        if moved then
          local okPush = false
          for _, c in ipairs(cells) do
            local back = lvl.nb[c][OPP[d]]
            if back ~= 0 and not occ[back] and reach(back, occ) then okPush = true; break end
          end
          if okPush then
            for _, t in ipairs(moved) do if inCol(t) then return true end end
            local r = fall(moved)
            local key = keyOf(r)
            if not seen[key] then seen[key] = true; qq[#qq + 1] = r end
          end
        end
      end
    end
    return false
  end
  for _, q in ipairs({ k.tee, k.plug, k.nip }) do
    local c = st.pos[q]
    if c ~= 0 and not st.fixed[q] and not inCol(c) and not canEnter(q) then return true end
  end
  return false
end

-- Абляции РОЛИ (фильтры ходов, как в levels/05.lua и levels/06.lua): каждая обязана сделать уровень нерешаемым.
local function colX(lvl) local k = find(lvl); return (xy(lvl, lvl.pieces[k.src].start)) end
local function inColumn(lvl, c) return c ~= 0 and (xy(lvl, c)) == colX(lvl) end
-- «Заглушка не едет раньше тройника»: запрещено состояние, где заглушка в столбе, а тройника там ещё нет.
local function plugNotFirst(lvl, st, ns)
  local k = find(lvl)
  return not (inColumn(lvl, ns.pos[k.plug]) and not inColumn(lvl, ns.pos[k.tee]))
end
-- «Струя не поднимает детали»: запрещено состояние, где незакреплённая деталь стоит в столбе над стояком.
local function noCargo(lvl, st, ns)
  for q, p in ipairs(lvl.pieces) do
    local c = ns.pos[q]
    if p.movable and c ~= 0 and not ns.fixed[q] and inColumn(lvl, c) then return false end
  end
  return true
end
-- «Лифт не перевозит через стенку»: тройник, въехав в столб, его не покидает, и Лапидус не забирается в струю,
-- пока ниппель не в основании (перебраться на другую сторону фонтана можно только верхом по полу).
local function noCrossing(lvl, st, ns)
  local k = find(lvl)
  if inColumn(lvl, st.pos[k.tee]) and not st.fixed[k.tee] and not inColumn(lvl, ns.pos[k.tee]) then return false end
  if ns.fixed[k.nip] then return true end
  local _, sy = xy(lvl, lvl.pieces[k.src].start)
  for _, c in ipairs(ns.body) do
    if inColumn(lvl, c) then local _, y = xy(lvl, c); if y >= sy - lvl.R then return false end end
  end
  return true
end

return {
  visibleLoss = visibleLoss,
  id = 7, flat = 7, name = "Дали напор",
  length = { 2, 5 }, pressure = 2, tile = "mint",
  stack = { "plug", "tee" }, -- задуманный порядок стопки сверху вниз (для проверок, в игре не используется)
  target = { moves = { 15, 40 }, states = 1000000, dead = 50, fb = 3 },
  grid = {
    "###########",
    "###########",
    "#####.#####",
    "#####..####",
    "###......##",
    "###...#...#",
    "#####.....#",
    "#####.#####",
    "###########",
  },
  objects = {
    { kind = "source", at = { 6, 8 }, ports = { up = "V" } },
    { kind = "fixture", what = "sink", at = { 7, 4 }, ports = { left = "V" } },
    { kind = "fitting", what = "tee", tag = "tee", at = { 5, 6 }, ports = { up = "N", right = "N", down = "V" } },
    { kind = "fitting", what = "plug", tag = "plug", at = { 7, 7 }, ports = { down = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 9, 7 }, ports = { up = "N", down = "N" } },
    { kind = "lapidus", cells = { { 8, 6 }, { 9, 6 }, { 10, 6 }, { 10, 7 } }, head = 4 },
  },
  ablations = {
    { name = "без заглушки", remove = "plug" },
    { name = "без ниппеля", remove = "nip" },
    { name = "струя не поднимает детали", filter = noCargo },
    { name = "заглушка не едет раньше тройника", filter = plugNotFirst },
    { name = "лифт не перевозит через стенку", filter = noCrossing },
  },
  texts = {
    request = "Воду дали. До потолка. Мойка не в курсе.",
    hints = {
      "Лифт кладёт груз стопкой: кто поехал первым, тот и наверху. Тройник к мойке поедет последним, но в очередь встанет заранее.",
      "Ваш звонок очень важен для нас. Уточните, как ваш тройник попадёт на ту сторону фонтана.",
      "Мастер выехал. Говорят, ваш лифт возит не только наверх, но и через стенку.",
    },
  },
}
