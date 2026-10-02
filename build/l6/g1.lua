return {
  id = 6, flat = 6, name = "Намертво", length = { 3, 5 }, pressure = 0,
  grid = {
    "#######",
    "###.###",
    "###.###",
    "#.....#",
    "#.....#",
    "##....#",
    "##....#",
    "###~###",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 4, 2 }, ports = { down = "N" } },
    { kind = "fitting", what = "coupling", tag = "nip", at = { 5, 4 }, ports = { up = "V", down = "V" } },
    { kind = "source", at = { 2, 5 }, ports = { right = "N" } },
    { kind = "lapidus", cells = { { 4, 6 }, { 4, 5 }, { 5, 5 }, { 5, 6 }, { 5, 7 } }, head = 5 },
  },
  ablations = { { name = "без ниппеля", remove = "nip" } },
}
