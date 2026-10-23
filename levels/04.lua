-- Кв. 4 «Резьба», кандидат t17 (build/l4e, раунд 4, три детали). доводка t16 по build/l4v3/VERIFY.md: муфта стоит там, куда падала (на голове Лапидуса); правило «вход закрыт» убрано, добавлено «прикручена к выходу трубы»; подсказки про выбор дыры; контроль «угольник мимо машинки запрещён».
-- Сгенерировано build/l4e/mk.lua из build/l4e/specs.lua. Решение здесь не пишется.
-- Видимый проигрыш уровня (только добавляет к общей линейке tools/vislib.lua: смыто, замёрзла, карман).
-- Видимо проиграно «с одного взгляда», если прикрученная деталь:
--  1) смотрит открытой резьбой в стену, в глухой бок закреплённого или в такую же резьбу другой закреплённой детали —
--     шов, который никогда не закрыть (угольник, прикрученный к муфте в шахте, резьбой в стену);
--  2) прикручена к выходу трубы шахты — единственный выход воды занят, а её свободная резьба смотрит вниз, в пол
--     (угольник, упавший мимо спуска и свинтившийся с трубой на лету; скептик build/l4v3: «порт занят, резьба явно
--     никуда не ведёт»).
-- Не помечает (мерка новичка, §7): деталь прикручена туда, где резьба подходит и открытая резьба смотрит в свободную
-- клетку (ниппель под машинкой), свободная деталь не на своей дороге (угольник, ушедший в спуск), порядок свободных
-- деталей. Правило «вход в шахту закрыт при пустом стояке» из k50 убрано: в этой раскладке такая ошибка недостижима.
local OPP = { 3, 4, 1, 2 }
local function visibleLoss(lvl, st)
  local occ = {}
  for q, p in ipairs(lvl.pieces) do
    if st.pos[q] ~= 0 then occ[st.pos[q]] = q elseif p.movable then return true end
  end
  for q, p in ipairs(lvl.pieces) do
    if p.movable and st.fixed[q] then
      for d = 1, 4 do
        local th = p.ports[d]
        if th then
          local t = lvl.nb[st.pos[q]][d]
          if t == 0 or lvl.cell[t] == 1 then return true end -- 1: в стену
          local r = occ[t]
          if r and st.fixed[r] then
            local th2 = lvl.pieces[r].ports[OPP[d]]
            if th2 == nil or th2 == th then return true end -- 1: в глухой бок или в такую же резьбу
            if lvl.pieces[r].kind == "pipe" and OPP[d] ~= 3 then return true end -- 2: прикручена к выходу трубы (не к её нижней резьбе, которой труба ловит ниппель)
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
-- Контроль «угольник мимо машинки запрещён»: свободный угольник не бывает ниже антресоли (несущая ошибка уровня снята —
-- уровень должен стать тривиальным).
local function elbowStaysUp(lvl, st, ns)
  local q = tagOf(lvl, "elb")
  local c = ns.pos[q]
  return c == 0 or ns.fixed[q] or math.floor((c - 1) / lvl.W) + 1 <= 3
end
-- Контроль «угольник только после ниппеля»: запрещено состояние, где угольник уже прикручен, а ниппель ещё свободен.
local function elbowBeforeNipple(lvl, st, ns)
  local qe, qn = tagOf(lvl, "elb"), tagOf(lvl, "nip")
  return not (ns.pos[qe] ~= 0 and ns.fixed[qe] and ns.pos[qn] ~= 0 and not ns.fixed[qn])
end
-- Контроль «ниппель не ловится машинкой»: боковая ловушка «сито» снята.
local function nippleNotCaught(lvl, st, ns)
  for q, p in ipairs(lvl.pieces) do if p.fixture then
    local t = lvl.nb[p.start][1]
    for r, pr in ipairs(lvl.pieces) do if pr.tag == "nip" and ns.pos[r] == t and ns.fixed[r] then return false end end
  end end
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
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 5, 5 }, ports = { up = "V", down = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 6, 3 }, ports = { up = "N", down = "N" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 6, 2 }, ports = { down = "N", left = "V" } },
    { kind = "lapidus", cells = { { 4, 6 }, { 5, 6 } }, head = 2 },
  },
  ablations = {
    { name = "без муфты", remove = "cpl" },
    { name = "без ниппеля", remove = "nip" },
    { name = "без угольника", remove = "elb" },
    { name = "по одной нельзя", filter = oneByOne },
  },
  -- Контроли (должны оставаться РЕШАЕМЫМИ; проверка — build/l4e/ctrl.lua).
  controls = {
    { name = "контроль: угольник мимо машинки запрещён (несущая ошибка снята)", filter = elbowStaysUp },
    { name = "контроль: ниппель не ловится машинкой (боковая ловушка снята)", filter = nippleNotCaught },
    { name = "контроль: угольник ставят только после ниппеля", filter = elbowBeforeNipple },
    { name = "контроль: муфта с самого начала на стояке", mutate = function(d) for _, o in ipairs(d.objects) do if o.tag == "cpl" then o.at = { 2, 7 } end end end },
  },
  texts = {
    request = "Бельё замочено в машинке. Воду отключили. Бельё ждёт, я тоже.",
    card = "card05",
    hints = {
      "Дыра над машинкой — не мусоропровод: в неё падает только то, что должно на машинке и остаться. Всему остальному — спуск. А что упало не в свою дыру, снизу уже не поднять.",
      "Ваш звонок очень важен для нас. Уточняем, в какую дыру у вас что упало.",
      "Мастер выехал. Говорит, машинка ловит всё, что резьбой вниз, и ничего не отдаёт.",
    },
  },
}
