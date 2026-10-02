-- Квартира 7 «Дали напор» (29.09.2026, раунд 2) — ядро L7D «перевёрнутый тройник — лифт» (build/l7c/d_tee_lift),
-- доведённое по спискам слепых скептиков build/l7v_d/VERIFY.md и build/l7v_e/VERIFY.md (журнал — build/l7d/LOG.md,
-- итоги — build/l7d/REPORT.md, раздел «Раунд 2»). Раскладка — build/l7d/c/d22.lua.
-- Тройник прикручен к сети отводом вверх: из него бьют фонтан (напор 3 — столб в три клетки, над ним шахта до потолка)
-- и боковая струя вдоль пола к ванне. Фонтан — лифт. В финале отвод вверх переходит в угольник (Н вниз, Н вправо),
-- боковой выход глушит заглушка, Лапидус — от угольника до ванны (голова В на Н угольника, ноги Н в В ванны).
-- «Ага»: фонтан можно заткнуть собой — Лапидуса, у которого над плечами потолок, струя не поднимет, и деталь под ним
-- в столбе стоит. Потолков два: над подсобкой у основания и над шахтой у верхушки; приём нужен дважды, и порядок деталей
-- решает всё: угольник, прикрученный раньше, чем закрыт боковой выход, своей струёй сметает заглушку с единственного
-- пути к выходу. Шахта над фонтаном узкая (правый ствол — две клетки, (6,4) — стена): деталь на верхушке
-- перекладывают, стоя в шахте под потолком. Ниши и лишних клеток нет (скептик E: ниша держала метрику, не решение).
-- Ложный план: заглушка лежит у самого фонтана — пусть покатается наверх и упадёт в боковой выход, угольник потом.
-- Поле 9×9 (§6 — 12×9: поправить строку). Решение здесь не пишется.

-- Видимый проигрыш — мерка новичка (docs/DESIGN.md §7) целиком по общей линейке tools/vislib.lua (M.POCKET = 4): смыта;
-- нужная деталь больше никогда не сдвинется; деталь запечатана в кармане без своего места. Собственных правил у уровня нет.

-- Абляции роли приёмов (фильтры ходов, как в levels/05.lua и 06.lua).
local function find(lvl, what)
  for q, p in ipairs(lvl.pieces) do if p.what == what then return q end end
end
local function row(lvl, c) return math.floor((c - 1) / lvl.W) + 1 end
-- клетки столба фонтана (струя вверх не от Лапидуса)
local function fountain(lvl, ns)
  local R = require("core.rules")
  local col = {}
  for _, j in ipairs(R.jets(lvl, ns)) do
    if j.dir == R.UP and not j.lapidus then for _, c in ipairs(j.cells) do col[c] = true end end
  end
  return col
end
-- «Угольник не катается на фонтане»: угольник никогда не выше своей стартовой строки.
local function elbowStaysLow(lvl, st, ns)
  local q = find(lvl, "elbow")
  local c = ns.pos[q]
  return c == 0 or row(lvl, c) >= row(lvl, lvl.pieces[q].start)
end
-- «Деталь под телом в столбе не удержать» (узкая, по скептику): запрещено состояние, где незакреплённая деталь стоит
-- в столбе фонтана, а клетка прямо над ней — клетка Лапидуса.
local function noHold(lvl, st, ns)
  if ns.dead then return true end
  local col = fountain(lvl, ns)
  local body = {}
  for _, c in ipairs(ns.body) do body[c] = true end
  for q, p in ipairs(lvl.pieces) do
    local c = ns.pos[q]
    if p.movable and c ~= 0 and not ns.fixed[q] and col[c] and body[lvl.nb[c][1]] then return false end
  end
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
  id = 7, flat = 7, name = "Дали напор",
  length = { 2, 5 }, pressure = 3, tile = "mint",
  target = { moves = { 15, 40 }, states = 50000, dead = 55, fb = 3 },
  grid = {
    "#########",
    "####..###",
    "####..###",
    "####.####",
    "##....###",
    "#......##",
    "#......##",
    "######.##",
    "#########",
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
    { name = "деталь под телом в столбе не удержать", filter = noHold },
    { name = "в основании фонтана деталь не удержать", filter = noLid },
  },
  texts = {
    request = "Дали напор. Из пола бьёт фонтан, из стены — струя, ванна сухая. Красиво, но я заказывал ванну, а не Петергоф.",
    card = "card07", -- вкладыш «8 · Струя толкает и держит» (с панелью «Лапидус в струе») на экране заявки
    hints = {
      "Затыкать фонтан — последнее дело: его струя потом сметёт всё, что ещё не на месте. А пока он бьёт — сядьте на него под потолком: пусть подержит.",
      "Ваш звонок очень важен для нас. Проверяем, кто у вас первым уехал наверх.",
      "Мастер выехал. Говорит, у вас можно сидеть на фонтане, и ему это нравится.",
    },
  },
}
