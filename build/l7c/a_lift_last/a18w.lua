-- a18 (напор 3): антресоль слева от верхушки фонтана: муфта, переходник, угольник в ряд. Толкать ряд вправо:
-- угольник уходит на фонтан и дальше падает в прорезь у основания, переходник остаётся плясать на фонтане.
-- Лишний толчок ставит на фонтан муфту. Финал: угольник сбоку глушит фонтан, переходник падает в ванну.
-- Видимый проигрыш (широкий): деталь, прижатая к стене так, что её уже не сдвинуть (на полу справа у стены,
-- на антресоли у левой стены); угольник, закреплённый не в стояке; переходник, закреплённый не в ванне.
-- Широкий: плюс муфта, закреплённая где угодно (вход ванны «не той резьбой»); плюс фонтан заглушён, а переходник не в ванне.
local function visibleLoss(lvl, st)
  local W = lvl.W
  local function xy(c) return (c - 1) % W + 1, math.floor((c - 1) / W) + 1 end
  local Q = {}
  for q, p in ipairs(lvl.pieces) do if p.tag then Q[p.tag] = q end end
  for q, p in ipairs(lvl.pieces) do
    if p.movable and st.pos[q] ~= 0 then
      local x, y = xy(st.pos[q])
      if not st.fixed[q] then
        if (x == 9 and y == 6) or (x == 2 and y == 3) then return true end
      else
        if p.tag == "elb" and not (x == 6 and y == 6) then return true end
        if p.tag == "adp" and not (x == 6 and y == 4) then return true end
        if p.tag == "cpl" then return true end
      end
    end
  end
  if st.fixed[Q.elb] and not st.fixed[Q.adp] then return true end
  return false
end
return {
  visibleLoss = visibleLoss,
  id = 7, flat = 7, name = "Дали напор",
  length = { 2, 5 }, pressure = 3,
  grid = {
    "##########",
    "#........#",
    "#........#",
    "####.....#",
    "#####....#",
    "#####....#",
    "#####.####",
    "##########",
  },
  objects = {
    { kind = "source", at = { 6, 7 }, ports = { up = "N" } },
    { kind = "fixture", what = "bath", at = { 5, 4 }, ports = { right = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 3, 3 }, ports = { left = "V", right = "V" } },
    { kind = "fitting", what = "nipple", tag = "adp", at = { 4, 3 }, ports = { left = "V", right = "N" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 5, 3 }, ports = { down = "V", right = "V" } },
    { kind = "lapidus", cells = { { 9, 6 }, { 8, 6 } }, head = 2 },
  },
}
