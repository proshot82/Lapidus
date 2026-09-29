-- Кв. 4 «Резьба», кандидат t18 (build/l4e, раунд 4, три детали). t16, старт Лапидуса столбиком в колонне спуска (5,6)-(5,5)
-- Сгенерировано build/l4e/mk.lua из build/l4e/specs.lua. Решение здесь не пишется.
-- Видимый проигрыш уровня (только добавляет к общей линейке tools/vislib.lua: смыто, замёрзла, карман).
-- Видимо проиграно «с одного взгляда», если:
--  1) вход в шахту закрыт закреплённой деталью, а на стояке пусто (единственный вход закрыт навсегда);
--  2) прикрученная деталь смотрит открытой резьбой в стену, в глухой бок закреплённого или в такую же резьбу другой
--     закреплённой детали — шов, который никогда не закрыть: деталь стоит намертво, вставить туда ничего нельзя
--     (угольник, прикрученный к муфте в шахте, резьбой в стену; переходник над муфтой резьбой В к В).
-- Не помечает (мерка новичка, §7): деталь прикручена туда, где резьба подходит и открытая резьба смотрит в свободную
-- клетку (ниппель под машинкой, угольник на выходе шахты), свободная деталь не на своей дороге, порядок свободных
-- деталей и подвижную пару.
local OPP = { 3, 4, 1, 2 }
local function visibleLoss(lvl, st)
  local S
  for q, p in ipairs(lvl.pieces) do if p.source then S = p.start end end
  local B = lvl.nb[S][1]; local T = lvl.nb[B][1]
  local atB, atT = false, false
  local occ = {}
  for q, p in ipairs(lvl.pieces) do
    if st.pos[q] ~= 0 then occ[st.pos[q]] = q end
    if p.movable then
      if st.pos[q] == 0 then return true end
      if st.pos[q] == B and st.fixed[q] then atB = true end
      if st.pos[q] == T and st.fixed[q] then atT = true end
    end
  end
  if atT and not atB then return true end -- 1
  for q, p in ipairs(lvl.pieces) do
    if p.movable and st.fixed[q] then
      for d = 1, 4 do
        local th = p.ports[d]
        if th then
          local t = lvl.nb[st.pos[q]][d]
          if t == 0 or lvl.cell[t] == 1 then return true end -- 2: в стену
          local r = occ[t]
          if r and st.fixed[r] then
            local th2 = lvl.pieces[r].ports[OPP[d]]
            if th2 == nil or th2 == th then return true end -- 2: в глухой бок или в такую же резьбу
          end
        end
      end
    end
  end
  return false
end
-- Абляции роли и контроли — фильтры ходов (lvl, st, ns): false запрещает переход в ns.
local function tagOf(lvl, tag) for q, p in ipairs(lvl.pieces) do if p.tag == tag then return q end end end
local function shaft(lvl)
  for q, p in ipairs(lvl.pieces) do if p.source then local B = lvl.nb[p.start][1]; return B, lvl.nb[B][1] end end
end
-- «По одной нельзя»: запрещено состояние, где муфта уже на стояке, а какая-то деталь ещё свободна.
local function oneByOne(lvl, st, ns)
  local B = shaft(lvl)
  local fixedB, freeOther = false, false
  for q, p in ipairs(lvl.pieces) do
    if p.movable then
      if ns.pos[q] == B and ns.fixed[q] then fixedB = true elseif ns.pos[q] ~= 0 and not ns.fixed[q] then freeOther = true end
    end
  end
  return not (fixedB and freeOther)
end
-- «Сито под машинкой отключено»: ни одна деталь не прикручивается ко входу машинки (переходник ставить некуда → нерешаем).
local function noWasherCatch(lvl, st, ns)
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
return {
  visibleLoss = visibleLoss,
  id = 4, flat = 4, name = "Резьба",
  length = { 2, 4 }, pressure = 0, tile = "mint",
  target = { moves = { 15, 40 }, states = 300000, dead = 40, fb = 2 },
  grid = {
    "#########",
    "#####.###",
    "####...##",
    "####.#.##",
    "#......##",
    "#......##",
    "#.#######",
    "#.#######",
    "#########",
  },
  objects = {
    { kind = "source", at = { 2, 8 }, ports = { up = "N" } },
    { kind = "pipe", at = { 2, 5 }, ports = { right = "N", down = "V" } },
    { kind = "fixture", what = "washer", at = { 7, 6 }, ports = { up = "V" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 5, 3 }, ports = { up = "V", down = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 6, 3 }, ports = { up = "N", down = "N" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 6, 2 }, ports = { down = "N", left = "V" } },
    { kind = "lapidus", cells = { { 5, 6 }, { 5, 5 } }, head = 2 },
  },
  ablations = {
    { name = "без муфты", remove = "cpl" },
    { name = "без ниппеля", remove = "nip" },
    { name = "без третьей детали", remove = "elb" },
    { name = "по одной нельзя", filter = oneByOne },
    { name = "сито под машинкой отключено", filter = noWasherCatch },
  },
  -- Контроли (должны оставаться РЕШАЕМЫМИ; проверка — build/l4e/ctrl.lua): лёгкие версии без той или иной ловушки.
  controls = {
    { name = "контроль: угольник с самого начала на машинке", mutate = function(d) for _, o in ipairs(d.objects) do if o.tag == "elb" then o.at = { 7, 5 } end end end },
    { name = "контроль: муфта с самого начала на стояке", mutate = function(d) for _, o in ipairs(d.objects) do if o.tag == "cpl" then o.at = { 2, 7 } end end end },
    { name = "контроль: ниппель не ловится машинкой", filter = function(lvl, st, ns)
        for q, p in ipairs(lvl.pieces) do if p.fixture then
          local t = lvl.nb[p.start][1]
          for r, pr in ipairs(lvl.pieces) do if pr.tag == "nip" and ns.pos[r] == t and ns.fixed[r] then return false end end
        end end
        return true end },
    { name = "контроль: угольник не прикручивается к отводу шахты", filter = function(lvl, st, ns)
        local S; for q, p in ipairs(lvl.pieces) do if p.source then S = p.start end end
        local out = lvl.nb[lvl.nb[lvl.nb[S][1]][1]][1] -- клетка отвода шахты
        for r, pr in ipairs(lvl.pieces) do
          if pr.tag == "elb" and ns.pos[r] ~= 0 and ns.fixed[r] then
            for d = 1, 4 do if lvl.nb[ns.pos[r]][d] == out then return false end end
          end
        end
        return true end },
  },
  texts = {
    request = "Бельё замочено в машинке. Воду отключили. Бельё ждёт, я тоже.",
    card = "card04",
    hints = {
      "Резьба сама решает, кому где висеть: что подошло — то и прикрутилось, навсегда. Прежде чем толкать деталь к дыре, посмотрите, какой резьбой она туда войдёт.",
      "Ваш звонок очень важен для нас. Проверяем, не слиплось ли у вас что-нибудь лишнее.",
      "Мастер выехал. Детали он тоже роняет по одной.",
    },
  },
}
