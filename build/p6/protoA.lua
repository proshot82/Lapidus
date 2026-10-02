-- Прототип А из внешнего ревью 03.10 («Сначала пройди сам»): проверка на движке игры. Решение не записано.
return {
  id = 91, flat = 91, name = "Сначала пройди сам",
  length = { 3, 5 }, pressure = 0, tile = "mint",
  grid = {
    "###########",
    "#....######",
    "#....######",
    "#........##",
    "#....######",
    "###########",
  },
  objects = {
    { kind = "source", at = { 5, 5 }, ports = { up = "N" } },
    { kind = "fixture", what = "toilet", at = { 9, 4 }, ports = { left = "N" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 5, 3 }, ports = { down = "V", right = "V" } },
    { kind = "lapidus", cells = { { 3, 4 }, { 4, 4 }, { 5, 4 } }, head = 1 },
  },
}
