-- скелет s9: как s8 (пол на ряду 9), слоты шире: колодец — x=7 ряды 4..9 (порт влево), x=3 ряды 6..9 (порт вправо);
-- дымоход — x=10 ряды 3..5 (влево), x=7 ряды 3 (вправо).
local R = {
"###########",
"#F#......##",
"#.#...b..a#",
"#.#...d..c#",
"#.....f..e#",
"#Sg...h12##",
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
  slots = { a = "left", c = "left", e = "left", b = "right",
            d = "left", f = "left", h = "left", j = "left", l = "left", n = "left", g = "right", i = "right", k = "right", m = "right" },
  starts = {
    withStart("#Sg...h12##"),
    withStart("#Sg...h21##"),
    withStart("#Sg...h13##", "#.....f2.e#"),
    withStart("#Sg...h31##", "#.....f2.e#"),
    withStart("#Sg...h32##", "#.....f.1e#"),
    withStart("#Sg...h23##", "#.....f.1e#"),
  },
  opts = { src = "up:V", fx = "down:N", len = { 2, 4 } },
  optsSrc = '{ src = "up:V", fx = "down:N", len = { 2, 4 } }',
}
