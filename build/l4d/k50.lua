-- Кв. 4 «Резьба», кандидат k50 (build/l4d, раунд 3): антресоль с люком; слева от люка муфта, справа у края ниппель,
-- Лапидус стоит слева от муфты. Люк — спуск муфты и лестница Лапидуса; правый край антресоли — спуск ниппеля прямо
-- к входу в шахту. Машинка стоит в приямке под полом у шахты (вход сверху) — сито: муфта проходит над входом, ниппель
-- к нему прикручивается. Под антресолью коридор в два ряда от люка до шахты, лишнего места нет. Поле 10×9, длина 2–4.
-- Решение здесь не пишется.

-- Видимый проигрыш уровня (только добавляет к общей линейке tools/vislib.lua: смыто, замёрзла, карман). Раунд 3, после
-- скептиков build/l4v и build/l4v2. Видимо проиграно «с одного взгляда», если:
--  1) вход в шахту закрыт закреплённой деталью, а на стояке пусто (единственный вход закрыт навсегда);
--  2) вход прибора (машинки) занят прикрученной деталью: воде туда не попасть;
--  3) «нечем поднять»: одиночная свободная деталь лежит на полу коридора, а между ней и входом в шахту — резьба в полу,
--     к которой она прикрутится при первом же толчке к шахте (поднять её с пола нечем, другой дороги нет).
-- Не помечает (это «ага» уровня и мерка знатока): порядок свободных деталей на полу и подвижную свинченную пару.
local OPP = { 3, 4, 1, 2 }
local function visibleLoss(lvl, st)
  local S
  for q, p in ipairs(lvl.pieces) do if p.source then S = p.start end end
  local B = lvl.nb[S][1]; local T = lvl.nb[B][1]
  local W = lvl.W
  local atB, atT = false, false
  for q, p in ipairs(lvl.pieces) do
    if p.movable then
      if st.pos[q] == 0 then return true end
      if st.pos[q] == B and st.fixed[q] then atB = true end
      if st.pos[q] == T and st.fixed[q] then atT = true end
    end
  end
  if atT and not atB then return true end -- 1
  -- резьбы приборов, смотрящие в ряд входа (вход машинки в полу)
  local inlet = {}
  for q, p in ipairs(lvl.pieces) do
    if p.fixture then for d = 1, 4 do if p.ports[d] then inlet[lvl.nb[p.start][d]] = p.ports[d] end end end
  end
  for q, p in ipairs(lvl.pieces) do
    if p.movable and st.pos[q] ~= 0 then
      local c = st.pos[q]
      if inlet[c] and st.fixed[q] then return true end -- 2
      if not st.fixed[q] then
        local paired = false
        for r, pr in ipairs(lvl.pieces) do if r ~= q and pr.movable and st.pos[r] ~= 0 and not st.fixed[r] and st.asm[r] == st.asm[q] then paired = true end end
        local rowC, rowT = math.floor((c - 1) / W), math.floor((T - 1) / W)
        if not paired and rowC == rowT and p.ports[3] then -- 3: лежит в ряду входа, резьба снизу
          local step = (T > c) and 1 or -1
          local x = c + step
          while x ~= T do
            if inlet[x] and inlet[x] ~= p.ports[3] then return true end
            x = x + step
          end
        end
      end
    end
  end
  return false
end

-- Абляция РОЛИ приёма (фильтр ходов): «сито отключено» — деталь, которую резьба в полу должна ловить, проходит над входом
-- машинки, не прикручиваясь (запрещаем состояния, где она прикручена во вход). Если приём «одна деталь проходит, другая
-- ловится» — ключевой, без него уровень должен стать другим (см. контроли в REPORT).
local function noSieve(lvl, st, ns)
  for q, p in ipairs(lvl.pieces) do
    if p.fixture then
      for d = 1, 4 do
        if p.ports[d] then
          local t = lvl.nb[p.start][d]
          for r, pr in ipairs(lvl.pieces) do if pr.movable and ns.pos[r] == t and ns.fixed[r] then return false end end
        end
      end
    end
  end
  return true
end
local function oneByOne(lvl, st, ns)
  local S
  for q, p in ipairs(lvl.pieces) do if p.source then S = p.start end end
  local B = lvl.nb[S][1]
  local fixedB, freeOther = false, false
  for q, p in ipairs(lvl.pieces) do
    if p.movable then
      if ns.pos[q] == B and ns.fixed[q] then fixedB = true elseif ns.pos[q] ~= 0 and not ns.fixed[q] then freeOther = true end
    end
  end
  return not (fixedB and freeOther)
end

return {
  visibleLoss = visibleLoss,
  id = 4, flat = 4, name = "Резьба",
  length = { 2, 4 }, pressure = 0, tile = "mint",
  target = { moves = { 15, 40 }, states = 300000, dead = 40, fb = 2 },
  grid = {
    "##########",
    "###.######",
    "###.....##",
    "#####.#.##",
    "###......#",
    "###......#",
    "######.#.#",
    "########.#",
    "##########",
  },
  objects = {
    { kind = "source", at = { 9, 8 }, ports = { up = "N" } },
    { kind = "pipe", at = { 9, 5 }, ports = { down = "V", left = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 5, 3 }, ports = { up = "V", down = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 7, 3 }, ports = { up = "N", down = "N" } },
    { kind = "fixture", what = "washer", at = { 7, 7 }, ports = { up = "V" } },
    { kind = "lapidus", cells = { { 4, 3 }, { 4, 2 } }, head = 1 },
  },
  ablations = {
    { name = "без муфты", remove = "cpl" },
    { name = "без ниппеля", remove = "nip" },
    { name = "сборка заранее", mutate = function(d) for _, o in ipairs(d.objects) do if o.tag == "cpl" then o.at = { 5, 3 } elseif o.tag == "nip" then o.at = { 5, 2 } end end end },
    { name = "по одной нельзя", filter = oneByOne },
  },
  -- Контроли (должны оставаться РЕШАЕМЫМИ; проверка — build/l4d/gates.lua): лёгкие версии без ловушки.
  controls = {
    { name = "контроль: без ловушки порядка — муфта с самого начала на стояке", mutate = function(d) for _, o in ipairs(d.objects) do if o.tag == "cpl" then o.at = { 9, 7 } end end end },
    { name = "контроль: без соседства — муфта с самого начала у входа в шахту", mutate = function(d) for _, o in ipairs(d.objects) do if o.tag == "cpl" then o.at = { 8, 6 } end end end },
    { name = "контроль: без сита — вход машинки закрыт стеной, финал через отвод сверху", mutate = function(d) d.grid[7] = "########.#"; for _, o in ipairs(d.objects) do if o.kind == "fixture" then o.at = { 3, 5 }; o.ports = { right = "V" } end end end },
    { name = "контроль: сито отключено (ниппель не прикручивается ко входу машинки)", filter = noSieve },
  },
  texts = {
    request = "Бельё замочено в машинке. Воду отключили. Бельё ждёт, я тоже.",
    card = "card04",
    hints = {
      "Резьба в шахте и резьба в полу — одно сито: что подходит одному, ловится другим. Труба соберётся сама, если каждая деталь придёт своей дорогой и в свой черёд.",
      "Ваш звонок очень важен для нас. Проверяем, не слиплось ли у вас что-нибудь лишнее.",
      "Мастер выехал. Детали он тоже роняет по одной.",
    },
  },
}
