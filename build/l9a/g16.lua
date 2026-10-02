-- Кв. 9 «Гребёнка», кандидат g16 (раунд 2, 02.10.2026) — g15, ниппель на клетку дальше от зазора (старт длиннее на ход): Лапидус не проходит над стопкой и не подставляет тело под тройник; ядро «стопка-лифт»: верхняя губа на высоте над гребнями, тройник поднимает на неё второй фонтан, когда под него подводят заглушку; g7 с ответами на вердикт слепого скептика build/l9v/VERIFY.md.
-- Устройство: гребёнка — две клетки трубы на полу с выходами вверх (два фонтана при напоре 2) и вправо; стояк под ней
-- через зазор, в зазор из подвала входит ниппель — «дали воду». Лапидус стартует в подвале у ниппеля (не впритык к
-- деталям): «собрать всухую» — осознанный поход на карниз, а не первый ход. На карнизе (высота второй клетки струи)
-- подряд тройник и заглушка; под краем карниза — глухой отвод (Н вправо): тройник, схваченный сухим ближним выходом,
-- смотрит боковой резьбой в него, а не в стену. Ванна наверху слева (вход справа), унитаз справа внизу за трубой;
-- справа от гребней — «губа» над глухой стеной, за ней шахта на площадку между трубами (под ней отвод Н вверх).
-- «Ага» (M10 + M9 + M5): сухая гребёнка хватает первую же сброшенную деталь намертво; дай воду — фонтаны держат детали
-- на гребнях и несут поверх выходов до губы и в шахту; ближний фонтан — для головы Лапидуса. Решение здесь не пишется.
-- Поле 14×10, длина 4–6, напор 2, деталей 3. Видимый проигрыш — общая линейка tools/vislib.lua плюс правила §7 ниже:
-- «резьба явно никуда не ведёт» (W), «порт сети занят навсегда» (T), «лежит там, где нечем поднять» (пол подвала),
-- «не с той стороны» (S: деталь на однорядном карнизе, Лапидус целиком за ней — обойти нельзя; прецедент levels/06.lua).

-- Фильтры абляций и контролей нужны только инструментам (luajit из корня репозитория); в собранную игру build/ не входит.
local okF, F = pcall(dofile, "build/l9a/filt.lua")
if not okF then F = {} end
local okF2, F2 = pcall(dofile, "build/l9a/filt2.lua")
if not okF2 then F2 = {} end
local R = require("core.rules")

-- Правила §7 уровня (мерка новичка), по отдельности — для инструментов (build/l9a/rules9.lua проверяет, что ни одно
-- не помечает живых состояний). visibleLoss — их объединение.
local RULES = {}
local function occupancy(st)
  local occ = {}
  for q = 1, #st.pos do if st.pos[q] ~= 0 then occ[st.pos[q]] = q end end
  return occ
end
-- W: у закреплённой детали резьба смотрит в стену или в глухой бок закреплённого — вечная течь, как только сеть намокнет
RULES.W = function(lvl, st)
  local occ, P = occupancy(st), lvl.pieces
  for q, p in ipairs(P) do
    local c = st.pos[q]
    if c ~= 0 and st.fixed[q] and p.movable then
      for d = 1, 4 do
        if p.ports[d] then
          local t = lvl.nb[c][d]
          if t == 0 or lvl.cell[t] == R.WALL then return true end
          local r = occ[t]
          if r and st.fixed[r] and not R.match(p.ports[d], P[r].ports[R.OPP[d]]) then return true end
        end
      end
    end
  end
  return false
end
-- T: порт мокрой сети (гребёнка, труба к прибору) занят навсегда закреплённой деталью без ответной резьбы
RULES.T = function(lvl, st)
  local occ, P = occupancy(st), lvl.pieces
  local w = R.water(lvl, st, occ, true)
  for q, p in ipairs(P) do
    local c = st.pos[q]
    if c ~= 0 and not p.movable and not p.fixture and w.wet[q] then
      for d = 1, 4 do
        if p.ports[d] then
          local t = lvl.nb[c][d]
          local r = t ~= 0 and occ[t] or nil
          if r and st.fixed[r] and P[r].movable and not R.match(p.ports[d], P[r].ports[R.OPP[d]]) then return true end
        end
      end
    end
  end
  return false
end
-- Пол подвала: деталь с карниза, упавшая в подвал, лежит там, где её нечем поднять (§7; прецедент levels/07.lua)
RULES.floor = function(lvl, st)
  for q, p in ipairs(lvl.pieces) do
    local c = st.pos[q]
    if c ~= 0 and p.movable and not st.fixed[q] and p.tag ~= "nip" then
      local _, y = R.xy(lvl, c)
      if y == lvl.H - 2 then return true end
    end
  end
  return false
end
-- S: свободная нужная деталь на однорядном карнизе (ряд 5, x ≤ 6), а Лапидус целиком за ней (правее/выше), не в жёлобе
-- и не в подвале — обойти деталь нельзя, толкать её можно только к жёлобу (сокобан; прецедент levels/06.lua)
RULES.S = function(lvl, st)
  for q, p in ipairs(lvl.pieces) do
    local c = st.pos[q]
    if c ~= 0 and p.movable and not st.fixed[q] and p.tag ~= "nip" then
      local x, y = R.xy(lvl, c)
      if y == 5 and x <= 6 then
        local leftSide = false
        for _, b in ipairs(st.body) do
          local bx, by = R.xy(lvl, b)
          if (by == 5 and bx < x) or (bx == 2 and by >= 6) or by == lvl.H - 2 then leftSide = true break end
        end
        if not leftSide then return true end
      end
    end
  end
  return false
end
local function visibleLoss(lvl, st)
  for _, f in pairs(RULES) do if f(lvl, st) then return true end end
  return false
end

return {
  id = 9, flat = 9, name = "Гребёнка",
  length = { 4, 6 }, pressure = 2, tile = "mustard",
  target = { moves = { 15, 40 }, states = 1000000, dead = 60, fb = 4 },
  visibleLoss = visibleLoss, visRules = RULES,
  grid = {
    "##############",
    "##############",
    "###........###",
    "#####...##.###",
    "#.......##.###",
    "#.###...##.###",
    "#.####.......#",
    "#......###.###",
    "######.#######",
    "##############",
  },
  objects = {
    { kind = "source", at = { 7, 9 }, ports = { up = "V" } },
    { kind = "pipe", what = "comb", tag = "m1", at = { 7, 7 }, ports = { down = "V", up = "N", right = "N" } },
    { kind = "pipe", what = "comb", tag = "m2", at = { 8, 7 }, ports = { left = "V", up = "N", right = "N" } },
    { kind = "pipe", what = "pipe", tag = "p1", at = { 9, 7 }, ports = { left = "V", right = "N" } },
    { kind = "pipe", what = "pipe", tag = "p1b", at = { 10, 7 }, ports = { left = "V", right = "N" } },
    { kind = "stub", tag = "stubT", at = { 11, 8 }, ports = { up = "N" } },
    { kind = "pipe", what = "pipe", tag = "p2", at = { 12, 7 }, ports = { left = "N", right = "N" } },
    { kind = "fixture", what = "toilet", at = { 13, 7 }, ports = { left = "V" } },
    { kind = "fixture", what = "bath", at = { 4, 3 }, ports = { right = "V" } },
    { kind = "stub", tag = "stubL", at = { 6, 6 }, ports = { right = "N" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 4, 8 }, ports = { up = "N", down = "N" } },
    { kind = "fitting", what = "plug", tag = "plug", at = { 5, 5 }, ports = { down = "V" } },
    { kind = "fitting", what = "tee", tag = "tee", at = { 6, 5 }, ports = { down = "V", left = "V", right = "V" } },
    { kind = "lapidus", cells = { { 2, 5 }, { 2, 6 }, { 2, 7 }, { 2, 8 }, { 3, 8 } }, head = 5 },
  },
  ablations = {
    { name = "без заглушки", remove = "plug" },
    { name = "без тройника", remove = "tee" },
    { name = "у гребёнки один выход вверх", mutate = F2.oneOutlet },
    { name = "фонтан не держит деталь", filter = F.noHover },
    { name = "с гребня не сдвинуть вбок", filter = F2.noRideMove },
    { name = "деталь не вдавить сверху", filter = F.noPushDown },
  },
  controls = {
    { name = "детали не трогают всухую", filter = F.dryHandsOff },
    { name = "заглушка не в ближний фонтан", filter = F.notAt and F.notAt("plug", 7, 6) },
    { name = "тройник не в фонтаны", filter = F.notAt and function(lvl, st, ns) return F.notAt("tee", 7, 6)(lvl, st, ns) and F.notAt("tee", 8, 6)(lvl, st, ns) end },
  },
  texts = {
    request = "Поставили гребёнку на две точки. Мастер сказал «теперь всем хватит», открыл стояк и ушёл. Хватило полу.",
    card = "card09",
    hints = {
      "Фонтан — не преграда, а конвейер: что на него упало, едет по гребням дальше, чем кажется. Но закрыть фонтан можно только после того, как по нему всё проехало.",
      "Ваш звонок очень важен для нас. Уточните, какой из двух фонтанов вы заткнули — и которым концом собирались входить в ванну.",
      "Мастер выехал. Говорит: заглушку по дороге не ставить, а придержать — над ней пройти; а в первый попавшийся фонтан заглушка — как ключ в первую попавшуюся дверь.",
    },
  },
}
