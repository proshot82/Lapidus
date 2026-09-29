-- скелет s6: как s5 (проход вертикальный слева, коридор (4..5,5), колодец 6..8 с полом на ряду 9, площадка 9..10 × 2..3),
-- но без крючьев в стене площадки (правая x=9 только ряды 6..9) и с напольными штуцерами (порт вверх) на ряду 8.
-- Требуется падение на кратчайшем пути (спуск в колодец — часть плана).
local R = {
"###########",
"##F##...12#",
"##.#a.....#",
"##.#b...###",
"##......###",
"##S#c...i##",
"####d...j##",
"####exyzk##",
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
  rows = R, needFall = true,
  slots = { a = "right", b = "right", c = "right", d = "right", e = "right", f = "right",
            i = "left", j = "left", k = "left", l = "left", x = "up", y = "up", z = "up" },
  air = { x = ".", y = ".", z = "." },
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
