local M = dofile("build/l6/mk.lua")
local out = {}
local function add(tag, rows, len, extra)
  local obj = {
    F = { kind = "fixture", what = "heater", ports = { down = "V" } },
    S = { kind = "source", ports = { right = "V" } },
    n = { kind = "fitting", what = "nipple", tag = "nip", ports = { up = "N", down = "N" } },
  }
  for k, v in pairs(extra or {}) do obj[k] = v end
  local d = M.def{ rows = rows, obj = obj, lap = { { 2, 4 }, { 3, 4 } }, length = len }
  d.tagname = tag; d.carry = "nip"
  out[#out + 1] = d
end
-- B: приподнятая полка справа
add("B1 shelf1", { "#########", "###F#####", "###n#####", "#.......#", "#.......#", "#....####", "#S...####", "###~#####" }, { 3, 5 })
add("B2 shelf2", { "#########", "###F#####", "###n#####", "#.......#", "#....####", "#....####", "#S...####", "###~#####" }, { 3, 5 })
add("B3 shelf1 narrow", { "########", "###F####", "###n####", "#......#", "#......#", "#....###", "#S...###", "###~####" }, { 3, 5 })
-- C: столбик в комнате
add("C1 pillar", { "########", "###F####", "###n####", "#......#", "#......#", "#....#.#", "#S...#.#", "###~####" }, { 3, 5 })
add("C2 ledge", { "########", "###F####", "###n####", "#......#", "#....###", "#......#", "#S.....#", "###~####" }, { 3, 5 })
-- D: полка слева над стояком
add("D1 lintel", { "########", "###F####", "#..n####", "#......#", "#......#", "#......#", "#S.....#", "###~####" }, { 3, 5 })
return out
