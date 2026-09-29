-- скелет s7: проход вертикальный слева (унитаз (2,2), шахта (2,3..4), коридор (2..3,5), стояк (2,6)); колодец 4..6 × 2..9
-- с полом на ряду 9 (нижний ярус); стена x=7 с гребнем (7,3) — через её верх (7,2) из дымохода 8..9 × 2..6 (старт на его полу, ряд 6)
-- переходят в колодец. Слоты: дымоход — x=10 ряды 3..6 (a,c,e,g, порт влево), x=7 ряды 3..4 (b,d, порт вправо);
-- колодец — x=7 ряды 5..9 (f,h,j,l,n — порт влево), x=3 ряды 7..9 (i,k,m — порт вправо).
local R = {
"###########",
"#F#......##",
"#.#...b..a#",
"#.#...d..c#",
"#.....f..e#",
"#S#...h12g#",
"##i...j####",
"##k...l####",
"##m...n####",
"###########",
}
local function withStart(r6, r5)
  local t = {}
  for i, r in ipairs(R) do t[i] = r end
  t[6] = r6; if r5 then t[5] = r5 end
  return t
end
return {
  rows = R, needFall = true,
  slots = { a = "left", c = "left", e = "left", g = "left", b = "right", d = "right",
            f = "left", h = "left", j = "left", l = "left", n = "left", i = "right", k = "right", m = "right" },
  starts = {
    withStart("#S#...h12g#"),
    withStart("#S#...h21g#"),
    withStart("#S#...h13g#", "#.....f2.e#"),
    withStart("#S#...h31g#", "#.....f2.e#"),
    withStart("#S#...h32g#", "#.....f.1e#"),
    withStart("#S#...h23g#", "#.....f.1e#"),
  },
  opts = { src = "up:V", fx = "down:N", len = { 2, 4 } },
  optsSrc = '{ src = "up:V", fx = "down:N", len = { 2, 4 } }',
}
