-- a19 (напор 3): ужатая a18. Антресоль (ряд из муфты, переходника, угольника) слева от верхушки фонтана,
-- над ней лаз; справа — только карман для U-образного Лапидуса. Финал — угольник сбоку, переходник падает в ванну.
-- Видимый проигрыш (широкий, скептик): нужная деталь (переходник или угольник) застряла там, откуда её уже не
-- сдвинуть: в правом столбце кармана (толкать некуда — стена) или у левой стены антресоли (толкнуть некому);
-- переходник, запертый на антресоли муфтой у стены.
local function visibleLoss(lvl, st)
  local W = lvl.W
  local function xy(c) return (c - 1) % W + 1, math.floor((c - 1) / W) + 1 end
  local Q = {}
  for q, p in ipairs(lvl.pieces) do if p.tag then Q[p.tag] = q end end
  for _, t in ipairs({ "adp", "elb" }) do
    local q = Q[t]
    if st.pos[q] ~= 0 and not st.fixed[q] then
      local x, y = xy(st.pos[q])
      if x == 8 then return true end
      if x == 2 and y == 3 then return true end
    end
  end
  local cx, cy = xy(st.pos[Q.cpl])
  local ax, ay = xy(st.pos[Q.adp])
  if not st.fixed[Q.adp] and cx == 2 and cy == 3 and ax == 3 and ay == 3 then return true end
  if st.fixed[Q.cpl] then return true end -- муфта закреплена (вход ванны «под ноги»)
  if st.fixed[Q.elb] and not st.fixed[Q.adp] then
    local x, y = xy(st.pos[Q.adp]); if not (x == 6 and y < 6) then return true end -- фонтан заглушён, переходник не над ванной
  end
  return false
end
return {
  visibleLoss = visibleLoss,
  id = 7, flat = 7, name = "Дали напор",
  length = { 2, 5 }, pressure = 3,
  grid = {
    "#########",
    "#.....###",
    "#......##",
    "####....#",
    "#####...#",
    "#####...#",
    "#####.###",
    "#########",
  },
  objects = {
    { kind = "source", at = { 6, 7 }, ports = { up = "N" } },
    { kind = "fixture", what = "bath", at = { 5, 4 }, ports = { right = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 3, 3 }, ports = { left = "V", right = "V" } },
    { kind = "fitting", what = "nipple", tag = "adp", at = { 4, 3 }, ports = { left = "V", right = "N" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 5, 3 }, ports = { down = "V", right = "V" } },
    { kind = "lapidus", cells = { { 8, 6 }, { 8, 5 } }, head = 2 },
  },
}
