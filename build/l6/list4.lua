local M = dofile("build/l6/mk.lua")
local out = {}
local function add(tag, rows, len, startLen)
  local obj = {
    F = { kind = "fixture", what = "heater", ports = { down = "V" } },
    S = { kind = "source", ports = { right = "V" } },
    n = { kind = "fitting", what = "nipple", tag = "nip", ports = { up = "N", down = "N" } },
  }
  local d = M.def{ rows = rows, obj = obj, lap = { { 3, 7 }, { 4, 7 } }, length = len }
  d.tagname = tag; d.carry = "nip"; d.startLen = startLen
  out[#out + 1] = d
end
add("C1 3x3+shaft2", { "#######", "###F###", "###n###", "###.###", "##...##", "##...##", "#S...##", "###~###" }, { 3, 5 }, { 3, 5 })
add("C2 4x3+shaft2", { "########", "###F####", "###n####", "###.####", "##....##", "##....##", "#S....##", "###~####" }, { 3, 5 }, { 3, 5 })
add("C3 3x3+shaft1", { "#######", "###F###", "###n###", "##...##", "##...##", "#S...##", "###~###" }, { 3, 5 }, { 3, 5 })
add("C4 4x3 shaft1", { "########", "###F####", "###n####", "##....##", "##....##", "#S....##", "###~####" }, { 3, 5 }, { 3, 5 })
add("C5 5x3 open-left", { "########", "###F####", "###n####", "#.....##", "#.....##", "#S....##", "###~####" }, { 3, 5 }, { 3, 5 })
add("C6 4x4", { "########", "###F####", "###n####", "##....##", "##....##", "##....##", "#S....##", "###~####" }, { 3, 5 }, { 3, 5 })
return out
