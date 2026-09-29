-- скелет s2: как s1, но без потолочных крючьев и со сливом под колодцем (срыв без захвата = смыт).
local rows = {
"###########",
"#S....F####",
"##.########",
"##.....b..#",
"###f....12#",
"###g....h##",
"###i....j##",
"###k....l##",
"###m....n##",
"####~~~~###",
}
local function withStart(r5, r4)
  local t = {}
  for i, r in ipairs(rows) do t[i] = r end
  t[5] = r5; if r4 then t[4] = r4 end
  return t
end
return {
  rows = rows,
  slots = { b = "left", f = "right", g = "right", i = "right", k = "right", m = "right",
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
