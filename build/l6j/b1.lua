-- b1: семейство B «подставка → звено». Стояк на дне шахты (резьба вверх), муфта вертикальная на уступе,
-- ниппель на полочке над уступом, прибор на уступе ярусом выше. Ложный план: муфту сразу в шахту (один-два толчка).
return {
  visibleLoss = dofile("build/l6j/vis.lua"),
  id = 6, flat = 6, name = "b1", length = { 2, 5 }, pressure = 0, tile = "mint",
  grid = {
    "########",
    "##.....#",
    "##.#...#",
    "#......#",
    "#......#",
    "#.######",
    "#.######",
    "#.######",
    "########",
  },
  objects = {
    { kind = "source", at = { 2, 8 }, ports = { up = "N" } },
    { kind = "fixture", what = "sink", at = { 6, 4 }, ports = { left = "V" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 4, 5 }, ports = { up = "V", down = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 4, 2 }, ports = { left = "N", right = "N" } },
    { kind = "lapidus", cells = { { 5, 5 }, { 6, 5 } }, head = 1 },
  },
  ablations = {
    { name = "без муфты", remove = "cpl" },
    { name = "без ниппеля", remove = "nip" },
  },
}
