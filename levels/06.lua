-- Квартира 6 «Намертво» (25.09.2026). Теорема «Он сам себе кран»: деталь на голове Лапидуса едет вверх,
-- а что лежит на нём, остаётся там, где он это оставил, и падает, когда он уходит.
-- Колонка висит в нише прямо над сливом, вход у неё снизу (резьба В): ниппель (Н/Н) попадает туда только снизу,
-- а держать его над сливом, кроме самого Лапидуса, некому. Стояк — в нише слева у пола.
-- Старт: Лапидус уже вкрутился в колонку — ногами; ниппель лежит у него на голове.
-- Раскладка найдена перебором семейства «коробка под колонкой» (build/l6: fam4.lua, sweep.lua) со всеми стартами
-- «Лапидус + деталь на спине» в общем графе. Абляции: без ниппеля; «кран запрещён» (деталь не поднимается);
-- «деталь не падает» (ничто не опускается на Лапидуса) — все три нерешаемы.
local function rowOf(lvl, c) return math.floor((c - 1) / lvl.W) end
local function noLift(lvl, st, ns)
  for q = 1, #st.pos do
    local a, b = st.pos[q], ns.pos[q]
    if a ~= 0 and b ~= 0 and rowOf(lvl, b) < rowOf(lvl, a) then return false end
  end
  return true
end
local function noDrop(lvl, st, ns)
  for q = 1, #st.pos do
    local a, b = st.pos[q], ns.pos[q]
    if a ~= 0 and b ~= 0 and lvl.pieces[q].movable and rowOf(lvl, b) > rowOf(lvl, a) then return false end
  end
  return true
end
-- видимый проигрыш для tools/review.lua: ниппель лёг на пол (поднять деталь с пола нельзя — только с Лапидуса)
local function visibleLoss(lvl, st)
  for q, p in ipairs(lvl.pieces) do
    if p.tag == "nip" and st.pos[q] ~= 0 and not st.fixed[q] then
      local b = lvl.nb[st.pos[q]][3]
      if b ~= 0 and lvl.cell[b] == 1 then return true end
    end
  end
  return false
end
return {
  visibleLoss = visibleLoss,
  id = 6, flat = 6, name = "Намертво",
  length = { 3, 5 }, pressure = 0, tile = "mustard",
  target = { moves = { 12, 40 }, states = 1000000, dead = 50, fb = 3 },
  grid = {
    "########",
    "###.####",
    "###.####",
    "##.....#",
    "##.....#",
    "#......#",
    "###~####",
  },
  objects = {
    { kind = "source", at = { 2, 6 }, ports = { right = "V" } },
    { kind = "fixture", what = "heater", at = { 4, 2 }, ports = { down = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 6, 4 }, ports = { up = "N", down = "N" } },
    { kind = "lapidus", cells = { { 4, 3 }, { 4, 4 }, { 5, 4 }, { 5, 5 }, { 6, 5 } }, head = 5 },
  },
  ablations = {
    { name = "без ниппеля", remove = "nip" },
    { name = "кран запрещён", filter = noLift },
    { name = "деталь не падает", filter = noDrop },
  },
  texts = {
    request = "Колонка без воды не зажигается. Хожу дома в ушанке. Прошу горячую воду.",
    hints = {
      "Он сам себе кран: что стоит у него на голове — едет вверх, что лежит на нём — остаётся там, где он это оставил.",
      "Ваш звонок очень важен для нас. Проверяем, не уронили ли вы что-нибудь в слив.",
      "Мастер выехал. Крана у него нет — он сам себе кран.",
    },
  },
}
