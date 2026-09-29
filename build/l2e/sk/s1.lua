-- скелет s1: проход наверху (S слева, F справа), лаз (3,3) над коридором (3..4,4); колодец 5..8 × 4..9 с полом;
-- площадка старта 9..10 × 4..5; слоты: c,d,e — потолочные крючья над колодцем; b — кронштейн у площадки (8,4);
-- f — левая стена на ряду 5; g,i,k,m — левая стена 6..9; h,j,l,n — правая стена 6..9.
local rows = {
"###########",
"#S....F####",
"##.#cde####",
"##.....b..#",
"###f....12#",
"###g....h##",
"###i....j##",
"###k....l##",
"###m....n##",
"###########",
}
local function withStart(r5, r4)
  local t = {}
  for i, r in ipairs(rows) do t[i] = r end
  t[5] = r5; if r4 then t[4] = r4 end
  return t
end
return {
  rows = rows,
  slots = { c = "down", d = "down", e = "down", b = "left", f = "right", g = "right", i = "right", k = "right", m = "right",
            h = "left", j = "left", l = "left", n = "left" },
  starts = {
    withStart("###f....12#"),
    withStart("###f....21#"),
    withStart("###f....13#", "##.....b2.#"),
    withStart("###f....31#", "##.....b2.#"),
    withStart("###f....32#", "##.....b.1#"),
    withStart("###f....23#", "##.....b.1#"),
  },
  opts = { src = "right:V", fx = "left:N", len = { 2, 4 } },
  optsSrc = '{ src = "right:V", fx = "left:N", len = { 2, 4 } }',
}
