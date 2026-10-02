-- a1: набросок. Заглушка на средней ступени, сброс в гнездо P (без слива), тройник на полке.
return {
  id = 5, flat = 5, name = "Лишний выход",
  length = { 2, 4 }, pressure = 0, tile = "blue",
  target = { moves = { 15, 40 }, states = 100000, dead = 35, fb = 1 },
  grid = {
    "#########",
    "#......##",
    "#..##..##",
    "#......##",
    "#.......#",
    "#......##",
    "####...##",
    "#########",
  },
  objects = {
    { kind = "source", at = { 7, 7 }, ports = { left = "N" } },
    { kind = "fixture", what = "dryer", at = { 8, 5 }, ports = { left = "N" } },
    { kind = "fitting", what = "tee", tag = "tee", at = { 4, 2 }, ports = { up = "V", right = "V", left = "V" } },
    { kind = "fitting", what = "plug", tag = "plug", at = { 4, 6 }, ports = { right = "N" } },
    { kind = "lapidus", cells = { { 2, 4 }, { 2, 5 }, { 2, 6 } }, head = 1 },
  },
  ablations = {
    { name = "без заглушки", remove = "plug" },
  },
}
