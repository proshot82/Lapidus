local sty = tonumber(os.getenv("STY") or 6)
return {
  id = 6, name = "e4", length = { 3, tonumber(os.getenv("LMAX") or 4) }, pressure = 0,
  grid = {
    "#######",
    "###.###",
    "##...##",
    "##...##",
    "##...##",
    "##...##",
    "##...##",
    "##...##",
    "#######",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 4, 2 }, ports = { down = "V" } },
    { kind = "source", at = { 5, 8 }, ports = { left = "V" } },
    { kind = "stub", at = { 3, sty }, ports = { right = "V" } },
    { kind = "fitting", what = "nipple", tag = "B", at = { 4, 5 }, ports = { up = "N", down = "N" } },
    { kind = "lapidus", cells = { { 4, 8 }, { 4, 7 }, { 4, 6 } }, head = 3 },
  },
}
