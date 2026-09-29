local C = dofile("build/l7e/cand.lua")
return C.build{ R = 3, rows = {
  "##########",
  "####..####",
  "####..####",
  "####.#####",
  "#p....####",
  "#fHn....##",
  "#S==Y...##",
  "#######F##",
  "##########",
}, legend = { Y = { kind = "pipe", what = "tee", ports = { left = "N", right = "V" } } } }
