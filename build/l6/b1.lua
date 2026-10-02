local M = dofile("build/l6/mk.lua")
return M.def{
  rows = { "#########", "###F#####", "###.#####", "#.......#", "#.......#", "#...n####", "#S...####", "###~#####" },
  obj = {
    F = { kind = "fixture", what = "heater", ports = { down = "V" } },
    S = { kind = "source", ports = { right = "V" } },
    n = { kind = "fitting", what = "nipple", tag = "nip", ports = { up = "N", down = "N" } },
  },
  lap = { { 5, 7 }, { 4, 7 }, { 4, 6 }, { 4, 5 }, { 5, 5 } },
  length = { 3, 5 },
}
