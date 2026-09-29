-- Кв. 4 «Резьба», кандидат t1 (build/l4e, раунд 4): три детали. Машинка стоит на антресоли, вход снизу (В вниз), под ним
-- дыра в полу антресоли — сито: деталь с резьбой Н сверху, вдвинутая под машинку, прикручивается и висит; муфта (В–В)
-- проваливается на пол. Шахта справа, закрытая отводом (В вниз, Н влево) — второе сито. Третья деталь — переходник
-- (Н сверху, В снизу) для входа машинки. Финал: Лапидус уголком от переходника (ногами вверх) до отвода шахты.
-- Решение здесь не пишется.
local function visibleLoss(lvl, st)
  local S
  for q, p in ipairs(lvl.pieces) do if p.source then S = p.start end end
  local B = lvl.nb[S][1]; local T = lvl.nb[B][1]
  local atB, atT = false, false
  for q, p in ipairs(lvl.pieces) do
    if p.movable then
      if st.pos[q] == 0 then return true end
      if st.pos[q] == B and st.fixed[q] then atB = true end
      if st.pos[q] == T and st.fixed[q] then atT = true end
    end
  end
  if atT and not atB then return true end -- вход в шахту закрыт при пустом стояке
  return false
end
return {
  visibleLoss = visibleLoss,
  id = 4, flat = 4, name = "Резьба",
  length = { 2, 4 }, pressure = 0, tile = "mint",
  target = { moves = { 15, 40 }, states = 300000, dead = 40, fb = 2 },
  grid = {
    "###########",
    "######.#.##",
    "#........##",
    "##.###.####",
    "#.........#",
    "#.........#",
    "#########.#",
    "#########.#",
    "###########",
  },
  objects = {
    { kind = "source", at = { 10, 8 }, ports = { up = "N" } },
    { kind = "pipe", at = { 10, 5 }, ports = { down = "V", left = "N" } },
    { kind = "fixture", what = "washer", at = { 7, 2 }, ports = { down = "V" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 4, 3 }, ports = { up = "V", down = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 5, 3 }, ports = { up = "N", down = "N" } },
    { kind = "fitting", what = "adapter", tag = "adp", at = { 6, 3 }, ports = { up = "N", down = "V" } },
    { kind = "lapidus", cells = { { 9, 3 }, { 9, 2 } }, head = 1 },
  },
  ablations = {
    { name = "без муфты", remove = "cpl" },
    { name = "без ниппеля", remove = "nip" },
    { name = "без переходника", remove = "adp" },
  },
  texts = {
    request = "Бельё замочено в машинке. Воду отключили. Бельё ждёт, я тоже.",
    card = "card04",
    hints = { "…", "Ваш звонок очень важен для нас. Проверяем, не слиплось ли у вас что-нибудь лишнее.", "Мастер выехал. Детали он тоже роняет по одной." },
  },
}
