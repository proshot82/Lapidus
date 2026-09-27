return {
  name = "Намертво", length = { 3, 5 }, startLen = { 3, 4 }, carry = "nip", lapHolder = { { 4, 7 }, { 5, 7 } },
  target = { moves = { 18, 36 } }, wallProb = 0.3, cap = 300000, out = "build/l6/bestA.lua",
  grid = {
    "#########",
    "#???.???#",
    "#???.???#",
    "#???.???#",
    "#???.???#",
    "#???.???#",
    "#??.....#",
    "####~####",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 5, 2 }, ports = { down = "V" } },
    { kind = "source", at = { 3, 7 }, ports = { right = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 5, 3 }, ports = { up = "N", down = "N" } },
  },
}
