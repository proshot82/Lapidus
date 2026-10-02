-- кандидат A1: табуретка (муфта В/В) под ниппелем — это недостающая труба стояка; отвод справа её «съедает»
local function visibleLoss(lvl, st)
  -- видимо потерян: ниппель лежит на полу, уступе или закреплённой детали — поднять его уже нечем
  for q, p in ipairs(lvl.pieces) do
    if p.tag == "nip" and st.pos[q] ~= 0 and not st.fixed[q] then
      local b = lvl.nb[st.pos[q]][3]
      if b ~= 0 and lvl.cell[b] == 1 then return true end
      for k = 1, #st.pos do if st.pos[k] == b and st.fixed[k] then return true end end
    end
  end
  return false
end
return {
  visibleLoss = visibleLoss,
  id = 6, flat = 6, name = "Намертво", length = { 3, 5 }, pressure = 0, tile = "mustard",
  grid = {
    "##########",
    "######.###",
    "#........#",
    "#........#",
    "#........#",
    "##########",
  },
  objects = {
    { kind = "source", at = { 2, 5 }, ports = { right = "N" } },
    { kind = "fixture", what = "heater", at = { 7, 2 }, ports = { down = "V" } },
    { kind = "stub", at = { 9, 5 }, ports = { left = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 7, 5 }, ports = { left = "V", right = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 7, 4 }, ports = { up = "N", down = "N" } },
    { kind = "lapidus", cells = { { 4, 5 }, { 5, 5 }, { 6, 5 } }, head = 3 },
  },
}
