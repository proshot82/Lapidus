local M = dofile("build/l6/mk.lua")
local out = {}
local function add(tag, rows, len, startLen)
  local obj = {
    F = { kind = "fixture", what = "heater", ports = { down = "V" } },
    S = { kind = "source", ports = { right = "V" } },
    n = { kind = "fitting", what = "nipple", tag = "nip", ports = { up = "N", down = "N" } },
  }
  local d = M.def{ rows = rows, obj = obj, lap = { { 2, 3 }, { 3, 3 } }, length = len }
  d.tagname = tag; d.carry = "nip"; d.fixedCarry = true; d.startLen = startLen
  out[#out + 1] = d
end
-- ниппель над сливом на спине: n в строке над телом в колонке слива
add("T1 5x3", { "#######", "###F###", "###.###", "#.....#", "#..n..#", "#S....#", "###~###" }, { 3, 5 }, { 3, 5 })
add("T2 6x3", { "########", "###F####", "###.####", "#......#", "#..n...#", "#S.....#", "###~####" }, { 3, 5 }, { 3, 5 })
add("T3 5x4", { "#######", "###F###", "###.###", "#.....#", "#.....#", "#..n..#", "#S....#", "###~###" }, { 3, 5 }, { 3, 5 })
add("T4 7x3", { "#########", "###F#####", "###.#####", "#.......#", "#..n....#", "#S......#", "###~#####" }, { 3, 5 }, { 3, 5 })
add("T5 5x3 L2-5", { "#######", "###F###", "###.###", "#.....#", "#..n..#", "#S....#", "###~###" }, { 2, 5 }, { 2, 5 })
return out
