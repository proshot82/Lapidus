-- Квартира 7 «Дали напор» — кандидат направления D «перевёрнутый тройник» (29.09.2026, build/l7c/d_tee_lift, раскладка z/g7r.lua).
-- Тройник прикручен к сети отводом вверх: из него бьют фонтан (напор 3 — столб в три клетки) и боковая струя вдоль пола.
-- Фонтан — лифт. В финале отвод вверх переходит в угольник (Н вниз, Н вправо), боковой выход глушит заглушка,
-- Лапидус — от угольника до ванны (голова В на Н угольника, ноги Н в В ванны).
-- «Ага»: фонтан можно заткнуть собой — Лапидуса, у которого над плечами потолок, струя не поднимет.
-- Ложный план: заглушка лежит у самого фонтана — пусть покатается и упадёт в боковой выход, угольник потом.
-- Всё выглядит правильно ещё долго (заглушка встаёт на место), но порядок уже не тот, и угольнику на фонтан не попасть.
-- Журнал поиска — build/l7c/d_tee_lift/LOG.md. Решение здесь не пишется.

-- Видимый проигрыш — мерка новичка (docs/DESIGN.md §7). Смытые детали и «нужная деталь больше никогда не сдвинется»
-- линейка tools/vislib.lua считает сама по графу; здесь — остальные правила новичка для этого поля:
--  1) деталь, которую надо поднять, лежит там, где её нечем поднять: незакреплённая деталь на полу ниже сети
--     (под неё не подлезть, фонтан в другом столбце), а обе детали в сборке стоят не ниже сети;
--  2) прибор навсегда занят деталью, чья резьба никуда не ведёт: деталь вкручена во вход ванны, остальные её резьбы
--     смотрят в стену (или их нет).
local function visibleLoss(lvl, st)
  local W = lvl.W
  local netRow, fx
  for q, p in ipairs(lvl.pieces) do
    if p.source then netRow = math.floor((p.start - 1) / W) + 1 end
    if p.fixture then fx = q end
  end
  for q, p in ipairs(lvl.pieces) do
    local c = st.pos[q]
    if p.movable and c ~= 0 then
      if not st.fixed[q] then
        local b = lvl.nb[c][3]
        if math.floor((c - 1) / W) + 1 > netRow and (b == 0 or lvl.cell[b] == 1) then return true end
      elseif fx then
        local into, other = false, false
        for d = 1, 4 do
          local th = p.ports[d]
          if th then
            local t = lvl.nb[c][d]
            local ft = lvl.pieces[fx].ports[(d + 1) % 4 + 1] -- резьба ванны навстречу
            if t ~= 0 and t == st.pos[fx] and ft and ft ~= th then into = true
            elseif t ~= 0 and lvl.cell[t] ~= 1 then other = true end
          end
        end
        if into and not other then return true end
      end
    end
  end
  return false
end

-- Абляции роли приёмов (фильтры ходов, как в levels/05.lua и 06.lua).
local function find(lvl, what)
  for q, p in ipairs(lvl.pieces) do if p.what == what then return q end end
end
local function row(lvl, c) return math.floor((c - 1) / lvl.W) + 1 end
-- «Угольник не катается на фонтане»: угольник никогда не выше своей стартовой строки.
local function elbowStaysLow(lvl, st, ns)
  local q = find(lvl, "elbow")
  local c = ns.pos[q]
  return c == 0 or row(lvl, c) >= row(lvl, lvl.pieces[q].start)
end
-- «Фонтан собой не заткнуть»: ни одна клетка Лапидуса не стоит в столбе фонтана (кататься на верхушке можно).
local function noCork(lvl, st, ns)
  if ns.dead then return true end
  local R = require("core.rules")
  local col = {}
  for _, j in ipairs(R.jets(lvl, ns)) do
    if j.dir == R.UP and not j.lapidus then for _, c in ipairs(j.cells) do col[c] = true end end
  end
  for _, c in ipairs(ns.body) do if col[c] then return false end end
  return true
end
-- «В основании фонтана деталь не удержать»: незакреплённая деталь не может стоять в первой клетке фонтана.
local function noLid(lvl, st, ns)
  if ns.dead then return true end
  local c1 = lvl.nb[lvl.pieces[find(lvl, "tee")].start][1]
  for q, p in ipairs(lvl.pieces) do if p.movable and ns.pos[q] == c1 and not ns.fixed[q] then return false end end
  return true
end

return {
  visibleLoss = visibleLoss,
  id = 7, flat = 7, name = "Дали напор",
  length = { 2, 5 }, pressure = 3, tile = "mint",
  target = { moves = { 15, 40 }, states = 50000, dead = 55, fb = 3 },
  grid = {
    "############",
    "####.......#",
    "###........#",
    "####.......#",
    "##.........#",
    "#..........#",
    "#..........#",
    "######.....#",
    "############",
  },
  objects = {
    { kind = "fitting", what = "elbow", tag = "elb", at = { 4, 5 }, ports = { down = "N", right = "N" } },
    { kind = "fitting", what = "plug", tag = "plug", at = { 4, 6 }, ports = { left = "N" } },
    { kind = "source", at = { 2, 7 }, ports = { right = "V" } },
    { kind = "pipe", what = "pipe", at = { 3, 7 }, ports = { left = "N", right = "V" } },
    { kind = "pipe", what = "pipe", at = { 4, 7 }, ports = { left = "N", right = "V" } },
    { kind = "pipe", what = "tee", at = { 5, 7 }, ports = { left = "N", up = "V", right = "V" } },
    { kind = "fixture", what = "bath", at = { 7, 8 }, ports = { up = "V" } },
    { kind = "lapidus", cells = { { 2, 6 }, { 3, 6 } }, head = 2 },
  },
  ablations = {
    { name = "без заглушки", remove = "plug" },
    { name = "без угольника", remove = "elb" },
    { name = "угольник не катается на фонтане", filter = elbowStaysLow },
    { name = "фонтан собой не заткнуть", filter = noCork },
    { name = "в основании фонтана деталь не удержать", filter = noLid },
  },
  texts = {
    request = "Дали напор: из пола фонтан, из стены струя, ванна сухая. Фонтан красивый, но я заказывал ванну.",
    card = "card07", -- вкладыш «8 · Струя толкает и держит» на экране заявки
    hints = {
      "Фонтан можно заткнуть собой: если над плечами потолок, струе вас не поднять.",
      "Ваш звонок очень важен для нас. Проверяем, в каком порядке у вас катаются детали.",
      "Мастер выехал. От фонтана он не бегает — он в нём стоит.",
    },
  },
}
