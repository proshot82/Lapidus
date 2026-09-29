-- build/l4e/specs.lua — описания кандидатов кв. 4 (раунд 4). Общий текст разметки (VIS), фильтров, абляций и текстов.
local S = {}

S.VIS = [==[
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
end]==]

S.FILTERS = [==[
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
-- Контроль «угольник только после ниппеля»: запрещено состояние, где угольник уже прикручен, а ниппель ещё свободен
-- (порядок этих двух не навязан — уровень остаётся решаемым).
local function elbowBeforeNipple(lvl, st, ns)
  local qe, qn = tagOf(lvl, "elb"), tagOf(lvl, "nip")
  return not (ns.pos[qe] ~= 0 and ns.fixed[qe] and ns.pos[qn] ~= 0 and not ns.fixed[qn])
end]==]

S.ABL = [==[
  ablations = {
    { name = "без муфты", remove = "cpl" },
    { name = "без ниппеля", remove = "nip" },
    { name = "без третьей детали", remove = "elb" },
    { name = "по одной нельзя", filter = oneByOne },
    { name = "сито под машинкой отключено", filter = noWasherCatch },
  },]==]

S.CTRL = [==[
  -- Контроли (должны оставаться РЕШАЕМЫМИ; проверка — build/l4e/ctrl.lua): лёгкие версии без той или иной ловушки.
  controls = {
    { name = "контроль: угольник ставят только после ниппеля", filter = elbowBeforeNipple },
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
  },]==]

S.TEXTS = [==[
  texts = {
    request = "Бельё замочено в машинке. Воду отключили. Бельё ждёт, я тоже.",
    card = "card04",
    hints = {
      "Резьба сама решает, кому где висеть: что подошло — то и прикрутилось, навсегда. Прежде чем толкать деталь к дыре, посмотрите, какой резьбой она туда войдёт.",
      "Ваш звонок очень важен для нас. Проверяем, не слиплось ли у вас что-нибудь лишнее.",
      "Мастер выехал. Детали он тоже роняет по одной.",
    },
  },]==]

local function base(t)
  t.length = t.length or { 2, 4 }
  return t
end

-- t2: W=12. Шахта x=11 (отвод В вниз/Н влево), дыра под машинкой (8,4), правый спуск (10,4) к самому входу, левый спуск
-- (5,4). Антресоль x=5..10: переходник (6,3), муфта (7,3), ниппель (9,3) — клетка выбора между дырой и спуском.
S.t2 = base{
  comment = "антресоль x5–10, дыра под машинкой (8,4), спуски (5,4) и (10,4); шахта x=11; ниппель на клетке выбора.",
  grid = {
    "############",
    "#######.####",
    "####......##",
    "####.##.#.##",
    "###........#",
    "###........#",
    "##########.#",
    "##########.#",
    "############",
  },
  objects = {
    { kind = "source", at = { 11, 8 }, ports = { up = "N" } },
    { kind = "pipe", at = { 11, 5 }, ports = { down = "V", left = "N" } },
    { kind = "fixture", what = "washer", at = { 8, 2 }, ports = { down = "V" } },
    { kind = "fitting", what = "adapter", tag = "adp", at = { 6, 3 }, ports = { up = "N", down = "V" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 7, 3 }, ports = { up = "V", down = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 9, 3 }, ports = { up = "N", down = "N" } },
    { kind = "lapidus", cells = { { 5, 6 }, { 6, 6 } }, head = 1 },
  },
}
-- t3: как t2, но ниппель и муфта слева от дыры (6,3),(7,3), переходник на клетке выбора (9,3); Лапидус стоит в левом спуске.
S.t3 = base{
  comment = "антресоль x5–10: [ниппель][муфта] слева от дыры, переходник справа на клетке выбора; спуски (5,4), (10,4); шахта x=11.",
  grid = {
    "############",
    "#######.####",
    "####......##",
    "####.##.#.##",
    "###........#",
    "###........#",
    "##########.#",
    "##########.#",
    "############",
  },
  objects = {
    { kind = "source", at = { 11, 8 }, ports = { up = "N" } },
    { kind = "pipe", at = { 11, 5 }, ports = { down = "V", left = "N" } },
    { kind = "fixture", what = "washer", at = { 8, 2 }, ports = { down = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 6, 3 }, ports = { up = "N", down = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 7, 3 }, ports = { up = "V", down = "V" } },
    { kind = "fitting", what = "adapter", tag = "adp", at = { 9, 3 }, ports = { up = "N", down = "V" } },
    { kind = "lapidus", cells = { { 5, 6 }, { 5, 5 }, { 5, 4 }, { 5, 3 } }, head = 4 },
  },
}
-- t4: t3 со стартом на полу под левым спуском.
S.t4 = base{
  comment = "как t3, старт Лапидуса на полу (4,6)-(5,6).",
  grid = S.t3.grid,
  objects = {
    { kind = "source", at = { 11, 8 }, ports = { up = "N" } },
    { kind = "pipe", at = { 11, 5 }, ports = { down = "V", left = "N" } },
    { kind = "fixture", what = "washer", at = { 8, 2 }, ports = { down = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 6, 3 }, ports = { up = "N", down = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 7, 3 }, ports = { up = "V", down = "V" } },
    { kind = "fitting", what = "adapter", tag = "adp", at = { 9, 3 }, ports = { up = "N", down = "V" } },
    { kind = "lapidus", cells = { { 4, 6 }, { 5, 6 } }, head = 2 },
  },
}
-- t5: новое ядро «машинка под полкой». Машинка стоит на полу коридора (7,6), вход сверху; над ним дыра в антресоли (7,4):
-- деталь, столкнутая в дыру, падает на машинку и, если у неё резьба Н снизу, прикручивается. Стояк x=10 с трубой до
-- антресоли (выход Н влево на (10,3)); правый спуск (9,4) к самому входу в шахту. Стопка на клетке выбора (8,3): снизу
-- переходник, сверху ниппель. Муфта уже на полу у входа.
S.t5 = base{
  comment = "машинка под полкой, стопка [ниппель над переходником] на клетке выбора (8,3), муфта на полу у входа.",
  grid = {
    "############",
    "#######.####",
    "######....##",
    "######.#..##",
    "######....##",
    "######....##",
    "#########.##",
    "#########.##",
    "############",
  },
  objects = {
    { kind = "source", at = { 10, 8 }, ports = { up = "N" } },
    { kind = "pipe", at = { 10, 5 }, ports = { down = "V", up = "N" } },
    { kind = "pipe", at = { 10, 4 }, ports = { down = "V", up = "N" } },
    { kind = "pipe", at = { 10, 3 }, ports = { down = "V", left = "N" } },
    { kind = "fixture", what = "washer", at = { 7, 6 }, ports = { up = "V" } },
    { kind = "fitting", what = "adapter", tag = "adp", at = { 8, 3 }, ports = { up = "V", down = "N" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 8, 2 }, ports = { up = "N", down = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 9, 6 }, ports = { up = "V", down = "V" } },
    { kind = "lapidus", cells = { { 8, 6 }, { 8, 5 } }, head = 2 },
  },
}
-- t6: зеркальное компактное ядро. Шахта слева (x=2), отвод шахты В вниз / Н вправо; машинка стоит на полу справа (7,6),
-- вход сверху (В), над ним дыра антресоли (7,4) — сито: деталь с резьбой Н снизу прикручивается к машинке, муфта нет.
-- Антресоль x=3..7: спуск (3,4) к самому входу в шахту, детали [муфта][ниппель][угольник], угольник — Н вниз, В влево.
-- Финал: Лапидус лежит в верхнем ряду коридора от угольника (ноги) до отвода шахты (голова).
S.t6 = base{
  comment = "зеркальное компактное ядро 9×9: шахта слева, машинка на полу справа под дырой антресоли, угольник Н вниз/В влево.",
  grid = {
    "#########",
    "#########",
    "##.....##",
    "##.###.##",
    "#......##",
    "#......##",
    "#.#######",
    "#.#######",
    "#########",
  },
  objects = {
    { kind = "source", at = { 2, 8 }, ports = { up = "N" } },
    { kind = "pipe", at = { 2, 5 }, ports = { down = "V", right = "N" } },
    { kind = "fixture", what = "washer", at = { 7, 6 }, ports = { up = "V" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 4, 3 }, ports = { up = "V", down = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 5, 3 }, ports = { up = "N", down = "N" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 6, 3 }, ports = { down = "N", left = "V" } },
    { kind = "lapidus", cells = { { 4, 6 }, { 5, 6 } }, head = 2 },
  },
}
S.t7 = base{
  comment = "t6 с порядком [муфта][угольник][ниппель]",
  grid = S.t6.grid,
  objects = {
    { kind = "source", at = { 2, 8 }, ports = { up = "N" } },
    { kind = "pipe", at = { 2, 5 }, ports = { down = "V", right = "N" } },
    { kind = "fixture", what = "washer", at = { 7, 6 }, ports = { up = "V" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 4, 3 }, ports = { up = "V", down = "V" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 5, 3 }, ports = { down = "N", left = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 6, 3 }, ports = { up = "N", down = "N" } },
    { kind = "lapidus", cells = { { 4, 6 }, { 5, 6 } }, head = 2 },
  },
}
S.t8 = base{
  comment = "t6 с порядком [угольник][муфта][ниппель]",
  grid = S.t6.grid,
  objects = {
    { kind = "source", at = { 2, 8 }, ports = { up = "N" } },
    { kind = "pipe", at = { 2, 5 }, ports = { down = "V", right = "N" } },
    { kind = "fixture", what = "washer", at = { 7, 6 }, ports = { up = "V" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 4, 3 }, ports = { down = "N", left = "V" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 5, 3 }, ports = { up = "V", down = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 6, 3 }, ports = { up = "N", down = "N" } },
    { kind = "lapidus", cells = { { 4, 6 }, { 5, 6 } }, head = 2 },
  },
}
S.t9 = base{
  comment = "t6 с порядком [ниппель][муфта][угольник]",
  grid = S.t6.grid,
  objects = {
    { kind = "source", at = { 2, 8 }, ports = { up = "N" } },
    { kind = "pipe", at = { 2, 5 }, ports = { down = "V", right = "N" } },
    { kind = "fixture", what = "washer", at = { 7, 6 }, ports = { up = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 4, 3 }, ports = { up = "N", down = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 5, 3 }, ports = { up = "V", down = "V" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 6, 3 }, ports = { down = "N", left = "V" } },
    { kind = "lapidus", cells = { { 4, 6 }, { 5, 6 } }, head = 2 },
  },
}
S.t10 = base{
  comment = "t6, старт Лапидуса в колонне дыры (7,5)-(7,4)",
  grid = S.t6.grid,
  objects = {
    { kind = "source", at = { 2, 8 }, ports = { up = "N" } },
    { kind = "pipe", at = { 2, 5 }, ports = { down = "V", right = "N" } },
    { kind = "fixture", what = "washer", at = { 7, 6 }, ports = { up = "V" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 4, 3 }, ports = { up = "V", down = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 5, 3 }, ports = { up = "N", down = "N" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 6, 3 }, ports = { down = "N", left = "V" } },
    { kind = "lapidus", cells = { { 7, 5 }, { 7, 4 } }, head = 2 },
  },
}
S.t11 = base{
  comment = "t6, старт Лапидуса на антресоли у спуска (3,3)-(3,4)?",
  grid = S.t6.grid,
  objects = {
    { kind = "source", at = { 2, 8 }, ports = { up = "N" } },
    { kind = "pipe", at = { 2, 5 }, ports = { down = "V", right = "N" } },
    { kind = "fixture", what = "washer", at = { 7, 6 }, ports = { up = "V" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 4, 3 }, ports = { up = "V", down = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 5, 3 }, ports = { up = "N", down = "N" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 6, 3 }, ports = { down = "N", left = "V" } },
    { kind = "lapidus", cells = { { 3, 4 }, { 3, 3 } }, head = 2 },
  },
}
-- t12: t6 + правое крыло: угольник справа от дыры (8,3), правая лесенка (9,4) с пола; ниппель может попасть под машинку
-- раньше угольника (ловушка «резьба подходит»), угольник при этом остаётся подвижным.
S.t12 = base{
  comment = "t6 с правым крылом: угольник (8,3) справа от дыры, лесенка (9,4); поле 11×9.",
  grid = {
    "###########",
    "###########",
    "##.......##",
    "##.###.#.##",
    "#........##",
    "#........##",
    "#.#########",
    "#.#########",
    "###########",
  },
  objects = {
    { kind = "source", at = { 2, 8 }, ports = { up = "N" } },
    { kind = "pipe", at = { 2, 5 }, ports = { down = "V", right = "N" } },
    { kind = "fixture", what = "washer", at = { 7, 6 }, ports = { up = "V" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 4, 3 }, ports = { up = "V", down = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 5, 3 }, ports = { up = "N", down = "N" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 8, 3 }, ports = { down = "N", left = "V" } },
    { kind = "lapidus", cells = { { 4, 6 }, { 5, 6 } }, head = 2 },
  },
}
-- t6w: t6 с замурованной клеткой (6,6) — единственной клеткой без роли (build/l4e/walls.lua): ширина 4 → 2.
S.t6w = base{
  comment = "t6 без клетки (6,6) — мёртвого пространства нет; поле 9×9, длина 2–4.",
  grid = {
    "#########",
    "#########",
    "##.....##",
    "##.###.##",
    "#......##",
    "#....#.##",
    "#.#######",
    "#.#######",
    "#########",
  },
  objects = S.t6.objects,
}
-- t6w5: t6w при длине 2–5 (для сведения).
S.t6w5 = base{ comment = "t6w, длина 2–5.", grid = S.t6w.grid, objects = S.t6.objects, length = { 2, 5 } }
-- t13: спуск (4,4) с «прихожей» (3,6) перед входом в шахту; угольник в нише над ниппелем.
S.t13 = base{
  comment = "спуск (4,4), прихожая (3,5)-(3,6) перед входом; [муфта][ниппель+угольник сверху].",
  grid = {
    "#########",
    "#####.###",
    "##.....##",
    "####.#.##",
    "#......##",
    "#......##",
    "#.#######",
    "#.#######",
    "#########",
  },
  objects = {
    { kind = "source", at = { 2, 8 }, ports = { up = "N" } },
    { kind = "pipe", at = { 2, 5 }, ports = { down = "V", right = "N" } },
    { kind = "fixture", what = "washer", at = { 7, 6 }, ports = { up = "V" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 5, 3 }, ports = { up = "V", down = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 6, 3 }, ports = { up = "N", down = "N" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 6, 2 }, ports = { down = "N", left = "V" } },
    { kind = "lapidus", cells = { { 4, 6 }, { 5, 6 } }, head = 2 },
  },
}
-- t14: раскладка t13 (спуск (5,4) прямо над стартом Лапидуса — муфта лежит у него на голове) с разметкой «в стену».
S.t14 = base{ comment = "раскладка t13, разметка с правилом «резьба в стену».", grid = S.t13.grid, objects = S.t13.objects }
-- t15: спуск (4,4) (прихожая — одна клетка (3,x)), муфта (4,3) над спуском падает на пол сразу.
S.t15 = base{
  comment = "спуск (4,4), муфта над ним падает на пол у прихожей; [ниппель+угольник] у дыры.",
  grid = {
    "#########",
    "#####.###",
    "##.....##",
    "###.##.##",
    "#......##",
    "#......##",
    "#.#######",
    "#.#######",
    "#########",
  },
  objects = {
    { kind = "source", at = { 2, 8 }, ports = { up = "N" } },
    { kind = "pipe", at = { 2, 5 }, ports = { down = "V", right = "N" } },
    { kind = "fixture", what = "washer", at = { 7, 6 }, ports = { up = "V" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 5, 3 }, ports = { up = "V", down = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 6, 3 }, ports = { up = "N", down = "N" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 6, 2 }, ports = { down = "N", left = "V" } },
    { kind = "lapidus", cells = { { 4, 6 }, { 5, 6 } }, head = 2 },
  },
}
-- t16: t14 без клеток антресоли (3,3),(4,3) — единственных без роли по замуровке.
S.t16 = base{
  comment = "t14 без мёртвых клеток антресоли (3,3),(4,3): антресоль x=5..7, спуск (5,4) над стартом Лапидуса.",
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
  objects = S.t13.objects,
}
S.t17 = base{
  comment = "t16, старт Лапидуса (3,6)-(4,6): муфта падает на пол сама",
  grid = S.t16.grid,
  objects = {
    { kind = "source", at = { 2, 8 }, ports = { up = "N" } },
    { kind = "pipe", at = { 2, 5 }, ports = { down = "V", right = "N" } },
    { kind = "fixture", what = "washer", at = { 7, 6 }, ports = { up = "V" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 5, 3 }, ports = { up = "V", down = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 6, 3 }, ports = { up = "N", down = "N" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 6, 2 }, ports = { down = "N", left = "V" } },
    { kind = "lapidus", cells = { { 3, 6 }, { 4, 6 } }, head = 2 },
  },
}
S.t18 = base{
  comment = "t16, старт Лапидуса столбиком в колонне спуска (5,6)-(5,5)",
  grid = S.t16.grid,
  objects = {
    { kind = "source", at = { 2, 8 }, ports = { up = "N" } },
    { kind = "pipe", at = { 2, 5 }, ports = { down = "V", right = "N" } },
    { kind = "fixture", what = "washer", at = { 7, 6 }, ports = { up = "V" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 5, 3 }, ports = { up = "V", down = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 6, 3 }, ports = { up = "N", down = "N" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 6, 2 }, ports = { down = "N", left = "V" } },
    { kind = "lapidus", cells = { { 5, 6 }, { 5, 5 } }, head = 2 },
  },
}
S.t19 = base{
  comment = "t16, старт (6,6)-(6,5) у машинки",
  grid = S.t16.grid,
  objects = {
    { kind = "source", at = { 2, 8 }, ports = { up = "N" } },
    { kind = "pipe", at = { 2, 5 }, ports = { down = "V", right = "N" } },
    { kind = "fixture", what = "washer", at = { 7, 6 }, ports = { up = "V" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 5, 3 }, ports = { up = "V", down = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 6, 3 }, ports = { up = "N", down = "N" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 6, 2 }, ports = { down = "N", left = "V" } },
    { kind = "lapidus", cells = { { 6, 6 }, { 6, 5 } }, head = 2 },
  },
}
S.t20 = base{
  comment = "t16, муфта уже на полу (4,6), старт (5,6)-(6,6)",
  grid = S.t16.grid,
  objects = {
    { kind = "source", at = { 2, 8 }, ports = { up = "N" } },
    { kind = "pipe", at = { 2, 5 }, ports = { down = "V", right = "N" } },
    { kind = "fixture", what = "washer", at = { 7, 6 }, ports = { up = "V" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 4, 6 }, ports = { up = "V", down = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 6, 3 }, ports = { up = "N", down = "N" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 6, 2 }, ports = { down = "N", left = "V" } },
    { kind = "lapidus", cells = { { 5, 6 }, { 6, 6 } }, head = 2 },
  },
}
S.t21 = base{
  comment = "t16, старт (3,5)-(3,6) в прихожей",
  grid = S.t16.grid,
  objects = {
    { kind = "source", at = { 2, 8 }, ports = { up = "N" } },
    { kind = "pipe", at = { 2, 5 }, ports = { down = "V", right = "N" } },
    { kind = "fixture", what = "washer", at = { 7, 6 }, ports = { up = "V" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 5, 3 }, ports = { up = "V", down = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 6, 3 }, ports = { up = "N", down = "N" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 6, 2 }, ports = { down = "N", left = "V" } },
    { kind = "lapidus", cells = { { 3, 5 }, { 3, 6 } }, head = 2 },
  },
}
return S
