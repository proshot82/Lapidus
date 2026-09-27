return {
  id = 6, flat = 6, name = "Намертво", length = { 3, 5 }, pressure = 0,
  grid = {
    "##########",
    "###.######",
    "###.######",
    "###.....##",
    "###.....##",
    "##......##",
    "###.....##",
    "###~######",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 4, 2 }, ports = { down = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 7, 5 }, ports = { up = "N", down = "N" } },
    { kind = "source", at = { 3, 6 }, ports = { right = "V" } },
    { kind = "lapidus", cells = { { 8, 7 }, { 7, 7 }, { 7, 6 }, { 6, 6 }, { 5, 6 } }, head = 5 },
  },
  ablations = { { name = "без ниппеля", remove = "nip" } },
}
