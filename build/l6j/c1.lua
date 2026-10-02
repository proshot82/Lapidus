-- c1: семейство C «табуретка → крюк». Стояк в яме в полу (резьба вверх), муфта вертикальная на полу — табуретка у левой
-- колонны к полке; ниппель на полке под потолком; мойка на ступеньке справа. Ложные планы: муфту сразу в яму;
-- лезть за ниппелем справа (без табуретки) и столкнуть его влево.
return {
  visibleLoss = dofile("build/l6j/vis.lua"),
  id = 6, flat = 6, name = "c1", length = { 2, 5 }, pressure = 0, tile = "mint",
  grid = {
    "#######",
    "##...##",
    "##.#.##",
    "##...##",
    "#....##",
    "#.....#",
    "#...###",
    "#.#####",
    "#######",
  },
  objects = {
    { kind = "source", at = { 2, 8 }, ports = { up = "N" } },
    { kind = "fixture", what = "sink", at = { 6, 6 }, ports = { left = "V" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 4, 7 }, ports = { up = "V", down = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 4, 2 }, ports = { left = "N", right = "N" } },
    { kind = "lapidus", cells = { { 2, 7 }, { 3, 7 } }, head = 2 },
  },
  ablations = {
    { name = "без муфты", remove = "cpl" },
    { name = "без ниппеля", remove = "nip" },
  },
}
