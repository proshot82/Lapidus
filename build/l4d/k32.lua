-- Кв. 4 «Резьба», кандидат k32 (build/l4d, раунд 2): угольник вместо ниппеля и неподвижного отвода — верхнее звено
-- само несёт резьбу под голову Лапидуса. Машинка висит под правым краем антресоли (угольник лежит на ней), вход снизу.
-- Люк в антресоли — лестница Лапидуса и спуск муфты; правый край — спуск угольника. Шахта закрыта сверху стеной,
-- вход только сбоку. Решение здесь не пишется.

-- Видимый проигрыш уровня (только добавляет к общей линейке tools/vislib.lua: смыто, замёрзла, карман).
-- Разметка раунда 2 (после слепого скептика build/l4v/VERIFY.md). Видимо проиграно «с одного взгляда», если:
--  1) вход в шахту закрыт закреплённой деталью, а деталь, которая должна стоять на стояке, на стояке не стоит
--     (единственный вход в шахту закрыт навсегда);
--  2) подвижная деталь намертво прикручена к глухому отводу вне финальной сети (вкладыш: «прикрученная — намертво»);
--  3) вход прибора (машинки) навсегда занят прикрученной деталью: воде туда уже не попасть.
-- Не помечает (это «ага» уровня и мерка знатока): порядок свободных деталей на полу и подвижную свинченную пару.
local function visibleLoss(lvl, st)
  local S, B, T
  for q, p in ipairs(lvl.pieces) do if p.source then S = p.start end end
  B = lvl.nb[S][1]; T = lvl.nb[B][1]
  local atB, atT = nil, nil
  for q, p in ipairs(lvl.pieces) do
    if p.movable then
      if st.pos[q] == 0 then return true end
      if st.pos[q] == B and st.fixed[q] then atB = q end
      if st.pos[q] == T and st.fixed[q] then atT = q end
    end
  end
  -- 1) вход закрыт, а на стояке пусто
  if atT and not atB then return true end
  for q, p in ipairs(lvl.pieces) do
    if not p.movable then
      for d = 1, 4 do
        if p.ports[d] then
          local t = lvl.nb[p.start][d]
          for r = 1, #st.pos do
            if lvl.pieces[r].movable and st.pos[r] == t and st.fixed[r] then
              -- 2) на глухом отводе; 3) во входе прибора
              if p.kind == "stub" or p.fixture then return true end
            end
          end
        end
      end
    end
  end
  return false
end

-- Абляция РОЛИ приёма (фильтр ходов): «по одной нельзя» — запрещено состояние, где нижняя деталь уже закреплена на стояке,
-- а верхняя ещё свободна (детали нельзя ронять по одной — только ставить вместе, собранной трубой).
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
    "#.....####",
    "#.......##",
    "#####...##",
    "#.......##",
    "#........#",
    "########.#",
    "########.#",
    "##########",
  },
  objects = {
    { kind = "source", at = { 9, 8 }, ports = { up = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 3, 3 }, ports = { up = "V", down = "V" } },
    { kind = "fitting", what = "angle", tag = "ang", at = { 7, 3 }, ports = { down = "N", left = "N" } },
    { kind = "fixture", what = "washer", at = { 7, 4 }, ports = { down = "V" } },
    { kind = "lapidus", cells = { { 6, 6 }, { 6, 5 } }, head = 1 },
  },
  ablations = {
    { name = "без муфты", remove = "cpl" },
    { name = "без угольника", remove = "ang" },
    { name = "сборка заранее", mutate = function(d) for _, o in ipairs(d.objects) do if o.tag == "cpl" then o.at = { 3, 3 } elseif o.tag == "nip" then o.at = { 3, 2 } end end end },
    { name = "по одной нельзя", filter = oneByOne },
  },
  texts = {
    request = "Бельё замочено в машинке. Воду отключили. Бельё ждёт, я тоже.",
    card = "card04",
    hints = {
      "Трубу заранее не собирают: детали роняют по одной — сначала муфту, потом ниппель. Свинтятся сами, на месте.",
      "Ваш звонок очень важен для нас. Проверяем, не слиплось ли у вас что-нибудь лишнее.",
      "Мастер выехал. Детали он тоже роняет по одной.",
    },
  },
}
