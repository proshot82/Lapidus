-- Квартира 7 «Дали напор» (29.09.2026, раунд 3) — ядро L7D «перевёрнутый тройник — лифт» с третьей деталью.
-- Раскладка — build/l7e/c/e17.lua; журнал — build/l7e/LOG.md, итоги — build/l7e/REPORT.md. Решение здесь не пишется.
-- Тройник прикручен к сети отводом вверх: из него бьют фонтан (напор 3 — столб в три клетки, над ним шахта до потолка)
-- и боковая струя вдоль пола к ванне. Фонтан — лифт: он поднимает и детали, и самого Лапидуса.
-- Финал: отвод вверх переходит в угольник (Н вниз, Н вправо); боковой выход закрывает пара «ниппель Н–Н + заглушка В»
-- (заглушка с внутренней резьбой сама на тройник не встаёт — ей нужен ниппель); Лапидус — от угольника к ванне.
-- «Ага» (M9): фонтан можно заткнуть собой — Лапидуса, у которого над телом потолок, струя не поднимет, и деталь под ним
-- в столбе стоит. Потолков два: над подсобкой у основания (пару держат и выталкивают вбок) и над шахтой у верхушки
-- (угольник вдавливают сверху). Резьба сильнее струи: что вошло в первую клетку струи, прикручивается.
-- Ловушки (общими словами): заглушка, пущенная в фонтан первой, поднимается мимо угольника на полке и свинчивается
-- с ним на лету — не та пара, навсегда; пара ниппель+заглушка, свинченная на полке, а не на полу, вниз уже не сойдёт;
-- заглушка на правом выходе угольника — «не туда»; угольник, вставший раньше пары, запирает её в подсобке.
-- Ложный план: «заглушка лежит у самого фонтана — пусть покатается и упадёт в боковой выход, угольник потом».
-- Поле 10×9 (§6 — 12×9: поправить строку), деталей 3.

-- Видимый проигрыш — мерка новичка (docs/DESIGN.md §7) целиком по общей линейке tools/vislib.lua (M.POCKET = 4).
-- Собственных правил visibleLoss у уровня нет.

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
-- «Деталь под телом в столбе не удержать» (узкая): запрещено состояние, где незакреплённая деталь стоит в столбе
-- фонтана, а клетка прямо над ней — клетка Лапидуса.
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
-- «Столб не поднимает Лапидуса»: неприкрученный Лапидус не бывает в клетках столба.
local function noLapRide(lvl, st, ns)
  if ns.dead then return true end
  local R = require("core.rules")
  local occ = {}
  for q = 1, #ns.pos do if ns.pos[q] ~= 0 then occ[ns.pos[q]] = q end end
  local w = R.water(lvl, ns, occ)
  if w.headQ or w.heelQ then return true end
  local col = fountain(lvl, ns)
  for _, c in ipairs(ns.body) do if col[c] then return false end end
  return true
end

return {
  id = 7, flat = 7, name = "Дали напор",
  length = { 2, 5 }, pressure = 3, tile = "mint",
  target = { moves = { 15, 40 }, states = 50000, dead = 55, fb = 3 },
  grid = {
    "##########",
    "####..####",
    "####..####",
    "####..####",
    "#.....####",
    "#.......##",
    "#.......##",
    "#######.##",
    "##########",
  },
  objects = {
    { kind = "fitting", what = "nipple", tag = "nip", at = { 3, 5 }, ports = { left = "N", right = "N" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 4, 5 }, ports = { down = "N", right = "N" } },
    { kind = "fitting", what = "plug", tag = "plug", at = { 4, 6 }, ports = { left = "V" } },
    { kind = "source", at = { 2, 7 }, ports = { right = "V" } },
    { kind = "pipe", what = "pipe", at = { 3, 7 }, ports = { left = "N", right = "V" } },
    { kind = "pipe", what = "pipe", at = { 4, 7 }, ports = { left = "N", right = "V" } },
    { kind = "pipe", what = "tee", at = { 5, 7 }, ports = { left = "N", up = "V", right = "V" } },
    { kind = "fixture", what = "bath", at = { 8, 8 }, ports = { up = "V" } },
    { kind = "lapidus", cells = { { 2, 6 }, { 3, 6 } }, head = 2 },
  },
  ablations = {
    { name = "без ниппеля", remove = "nip" },
    { name = "без угольника", remove = "elb" },
    { name = "без заглушки", remove = "plug" },
    { name = "угольник не катается на фонтане", filter = elbowStaysLow },
    { name = "деталь под телом в столбе не удержать", filter = noHold },
    { name = "в основании фонтана деталь не удержать", filter = noLid },
    { name = "столб не поднимает Лапидуса", filter = noLapRide },
  },
  texts = {
    request = "Дали напор. Из пола бьёт фонтан, из стены — струя, ванна сухая. Красиво, но я заказывал ванну, а не Петергоф.",
    card = "card07", -- вкладыш «8 · Струя толкает и держит» (с панелью «Лапидус в струе») на экране заявки
    hints = {
      "Фонтан можно заткнуть собой: у кого над плечами потолок, того струя не поднимет, а что под ним — удержит. Но всё, что вы пустите в фонтан без присмотра, он поднимет и отдаст первой подходящей резьбе.",
      "Ваш звонок очень важен для нас. Уточните, пожалуйста, кто у вас поехал наверх первым — и с кем он там свинтился.",
      "Мастер выехал. Говорит, что заглушка с внутренней резьбой на тройник не встаёт, и вообще ей нужен ниппель, а не приключения.",
    },
  },
}
