-- Кв. 9 «Гребёнка», кандидат g9 (раунд 2, 01.10.2026) — ответ на вердикт слепого скептика build/l9v/VERIFY.md.
-- Устройство: гребёнка — две клетки трубы на полу с выходами вверх (два фонтана при напоре 2) и вправо; стояк под ней
-- через зазор, в зазор из подвала входит ниппель — «дали воду». Лапидус стартует в подвале у ниппеля (не впритык к деталям).
-- Слева карниз на высоте гребней (ряд 4): на нём заглушка. Тройник лежит наверху справа, на полке над вторым фонтаном;
-- к нему идут через гребни и по карнизу-«губе» над шахтой. Ванна наверху слева (вход справа), унитаз справа внизу за
-- трубой; тройник должен упасть в шахту на площадку между трубами (под ней глухой отвод закрывает его нижний порт).
-- «Ага» (M10 + M9 + M5): фонтаны — конвейер и мост: тройник сброшен сверху на дальний гребень и съезжает по гребням на
-- губу и в шахту; заглушку по пути приходится придержать в ближнем столбе, чтобы пройти над ней; и закрыть дальний фонтан
-- можно только после того, как тройник над ним проехал. Решение здесь не пишется.
-- Поле 14×10, длина 4–6, напор 2, деталей 3. Видимый проигрыш — общая линейка tools/vislib.lua плюс правила §7 ниже:
-- «резьба явно никуда не ведёт» (W), «порт сети занят навсегда» (T) и «лежит там, где нечем поднять» (пол подвала).

-- Фильтры абляций и контролей нужны только инструментам (luajit из корня репозитория); в собранную игру build/ не входит.
local okF, F = pcall(dofile, "build/l9a/filt.lua")
if not okF then F = {} end
local okF2, F2 = pcall(dofile, "build/l9a/filt2.lua")
if not okF2 then F2 = {} end
local R = require("core.rules")

-- Правила §7 уровня (мерка новичка). Живые состояния не помечают по построению — проверяется инструментами.
local function visibleLoss(lvl, st)
  local occ = {}
  for q = 1, #st.pos do if st.pos[q] ~= 0 then occ[st.pos[q]] = q end end
  local P = lvl.pieces
  for q, p in ipairs(P) do
    local c = st.pos[q]
    if c ~= 0 and st.fixed[q] then
      for d = 1, 4 do
        if p.ports[d] then
          local t = lvl.nb[c][d]
          if p.movable then
            -- W: у закреплённой детали резьба смотрит в стену или в глухой бок закреплённого — вечная течь
            if t == 0 or lvl.cell[t] == R.WALL then return true end
            local r = occ[t]
            if r and st.fixed[r] and not R.match(p.ports[d], P[r].ports[R.OPP[d]]) then return true end
          elseif not p.fixture then
            -- T: порт закреплённой сети (гребёнка, труба, отвод) занят навсегда деталью без ответной резьбы
            local r = t ~= 0 and occ[t] or nil
            if r and st.fixed[r] and P[r].movable and not R.match(p.ports[d], P[r].ports[R.OPP[d]]) then return true end
          end
        end
      end
    end
    -- пол подвала: деталь с карниза или полки, упавшая в подвал, лежит там, где её нечем поднять
    if c ~= 0 and p.movable and not st.fixed[q] and p.tag ~= "nip" then
      local _, y = R.xy(lvl, c)
      if y == lvl.H - 2 then return true end
    end
  end
  return false
end

return {
  id = 9, flat = 9, name = "Гребёнка",
  length = { 4, 6 }, pressure = 2, tile = "mustard",
  target = { moves = { 15, 40 }, states = 1000000, dead = 60, fb = 4 },
  visibleLoss = visibleLoss,
  grid = {
    "##############",
    "####........##",
    "#####...###.##",
    "#...........##",
    "#.####..##..##",
    "#.###....#..##",
    "#.###........#",
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
    { kind = "stub", at = { 11, 8 }, ports = { up = "N" } },
    { kind = "pipe", what = "pipe", tag = "p2", at = { 12, 7 }, ports = { left = "N", right = "N" } },
    { kind = "fixture", what = "toilet", at = { 13, 7 }, ports = { left = "V" } },
    { kind = "fixture", what = "bath", at = { 5, 2 }, ports = { right = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 5, 8 }, ports = { up = "N", down = "N" } },
    { kind = "fitting", what = "plug", tag = "plug", at = { 5, 4 }, ports = { down = "V" } },
    { kind = "fitting", what = "tee", tag = "tee", at = { 10, 2 }, ports = { down = "V", left = "V", right = "V" } },
    { kind = "lapidus", cells = { { 2, 6 }, { 2, 7 }, { 2, 8 }, { 3, 8 }, { 4, 8 } }, head = 5 },
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
    { name = "дальний фонтан не закрывают раньше тройника", filter = F2.plugAfterTee },
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
