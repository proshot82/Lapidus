-- Кв. 4 «Резьба», кандидат t11 (build/l4e, раунд 4, три детали). t6, старт Лапидуса на антресоли у спуска (3,3)-(3,4)?
-- Сгенерировано build/l4e/mk.lua из build/l4e/specs.lua. Решение здесь не пишется.
-- Видимый проигрыш уровня (только добавляет к общей линейке tools/vislib.lua: смыто, замёрзла, карман).
-- Видимо проиграно «с одного взгляда», если:
--  1) вход в шахту закрыт закреплённой деталью, а на стояке пусто (единственный вход закрыт навсегда);
--  2) две закреплённые детали смотрят друг на друга открытыми несовпадающими резьбами (шов, который никогда не
--     закрыть: обе стоят намертво, между ними ничего не вставить) — например, переходник повис на отводе шахты
--     над муфтой резьбой В к резьбе В.
-- Не помечает (мерка новичка, §7): деталь прикручена туда, где резьба подходит (ниппель под машинкой), свободная
-- деталь не на своей дороге, порядок свободных деталей и подвижную пару.
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
        local t = th and lvl.nb[st.pos[q]][d] or 0
        local r = t ~= 0 and occ[t] or nil
        if r and st.fixed[r] and lvl.pieces[r].ports[OPP[d]] and lvl.pieces[r].ports[OPP[d]] == th then return true end -- 2
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
    { kind = "pipe", at = { 2, 5 }, ports = { right = "N", down = "V" } },
    { kind = "fixture", what = "washer", at = { 7, 6 }, ports = { up = "V" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 4, 3 }, ports = { up = "V", down = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 5, 3 }, ports = { up = "N", down = "N" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 6, 3 }, ports = { down = "N", left = "V" } },
    { kind = "lapidus", cells = { { 3, 4 }, { 3, 3 } }, head = 2 },
  },
  ablations = {
    { name = "без муфты", remove = "cpl" },
    { name = "без ниппеля", remove = "nip" },
    { name = "без третьей детали", remove = "elb" },
    { name = "по одной нельзя", filter = oneByOne },
    { name = "сито под машинкой отключено", filter = noWasherCatch },
  },
  controls = {},
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
