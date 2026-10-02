-- z1a: фонтан перевозит ниппель через стенку; боковая струя тройника доносит его до ванны; пробка — в кармане слева.
local MK = dofile("build/l7c/d_tee_lift/mk.lua")
return MK.build{
  rows = {
    "############",
    "#..........#",
    "#..........#",
    "#..........#",
    "#....#.....#",
    "#..c.#.....#",
    "#fHp.#.....#",
    "#S==T....F.#",
    "############",
  },
  legend = {
    S = { kind = "source", ports = { right = "V" } },
    ["="] = { kind = "pipe", what = "pipe", ports = { left = "N", right = "V" } },
    T = { kind = "pipe", what = "tee", ports = { left = "N", up = "V", right = "V" } },
    F = { kind = "fixture", what = "bath", ports = { left = "V" } },
    p = { kind = "fitting", what = "plug", ports = { down = "N" } },
    c = { kind = "fitting", what = "nipple", ports = { left = "N", right = "N" } },
  },
}
