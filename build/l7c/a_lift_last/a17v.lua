-- a17 (напор 3): антресоль над ванной с двумя переходниками; достать их можно только с верхушки фонтана.
-- Нужный (В|Н) делает вход ванны «под голову», муфта (В|В) — «под ноги» (а ноги нужны угольнику).
-- Угольник у фонтана — полочка, на которую падает переходник; им же глушат фонтан сбоку последним.
-- Видимый проигрыш (честный): деталь на полу справа за угольником или у стены (её уже не поднять и не подать
-- в фонтан); деталь, закреплённая не там (в ванне — только переходник, в стояке — только угольник).
local function visibleLoss(lvl, st)
  local W = lvl.W
  local function xy(c) return (c - 1) % W + 1, math.floor((c - 1) / W) + 1 end
  for q, p in ipairs(lvl.pieces) do
    if p.movable and st.pos[q] ~= 0 then
      local x, y = xy(st.pos[q])
      if not st.fixed[q] and y == 6 and x >= 7 then return true end
      if st.fixed[q] and p.tag == "elb" and not (x == 5 and y == 6) then return true end
    end
  end
  return false
end
return {
  visibleLoss = visibleLoss,
  id = 7, flat = 7, name = "Дали напор",
  length = { 2, 5 }, pressure = 3,
  grid = {
    "#########",
    "#.......#",
    "#.......#",
    "###.....#",
    "####....#",
    "####....#",
    "####.####",
    "#########",
  },
  objects = {
    { kind = "source", at = { 5, 7 }, ports = { up = "N" } },
    { kind = "fixture", what = "bath", at = { 4, 4 }, ports = { right = "N" } },
    { kind = "fitting", what = "nipple", tag = "adp", at = { 4, 3 }, ports = { left = "V", right = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 3, 3 }, ports = { left = "V", right = "V" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 6, 6 }, ports = { down = "V", right = "V" } },
    { kind = "lapidus", cells = { { 8, 6 }, { 7, 6 } }, head = 2 },
  },
}
