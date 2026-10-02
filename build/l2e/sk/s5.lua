-- скелет s5: проход вертикальный слева (унитаз (3,2), шахта (3,3..4), стояк (3,6)), коридор (4..5,5) в колодец 6..8 × 2..9
-- с ПОЛОМ на ряду 9 (нижний ярус); площадка старта 9..10 × 2..3. Слоты: левая стена x=5 ряды 3,4,6,7,8,9 (a..f),
-- правая x=9 ряды 4..9 (g..l).
local R = {
"###########",
"##F##...12#",
"##.#a.....#",
"##.#b...g##",
"##......h##",
"##S#c...i##",
"####d...j##",
"####e...k##",
"####f...l##",
"###########",
}
local function withStart(r2, r3)
  local t = {}
  for i, r in ipairs(R) do t[i] = r end
  t[2] = r2; t[3] = r3
  return t
end
return {
  rows = R,
  slots = { a = "right", b = "right", c = "right", d = "right", e = "right", f = "right",
            g = "left", h = "left", i = "left", j = "left", k = "left", l = "left" },
  starts = {
    withStart("##F##...12#", "##.#a.....#"),
    withStart("##F##...21#", "##.#a.....#"),
    withStart("##F##....1#", "##.#a....2#"),
    withStart("##F##....2#", "##.#a....1#"),
    withStart("##F##...12#", "##.#a....3#"),
    withStart("##F##...32#", "##.#a....1#"),
    withStart("##F##....1#", "##.#a...32#"),
    withStart("##F##....3#", "##.#a...12#"),
  },
  opts = { src = "up:V", fx = "down:N", len = { 2, 4 } },
  optsSrc = '{ src = "up:V", fx = "down:N", len = { 2, 4 } }',
}
