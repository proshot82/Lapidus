-- b11 (напор 3): b9, угольник пляшет на фонтане, на антресоли муфта и переходник
local __R = require("core.rules")
-- Видимый проигрыш (широкий, скептик): нужная деталь (переходник, угольник) зажата так, что её уже не сдвинуть
-- ни в одну сторону (с каждой стороны либо упор, либо толкать некому — стена или закреплённое), и она не в струе;
-- либо нужная деталь закреплена не на своём месте (угольник — только в основании фонтана, переходник — только у ванны).
local function visibleLoss(lvl, st)
  local W = lvl.W
  local piece = {}
  for q = 1, #st.pos do if st.pos[q] ~= 0 then piece[st.pos[q]] = q end end
  local function solid(c) if c == 0 or lvl.cell[c] == 1 then return true end local r = piece[c]; return r and st.fixed[r] end
  local jet = {}
  for _, j in ipairs(__R.jets(lvl, st)) do for _, c in ipairs(j.cells) do jet[c] = true end end
  local src
  for _, p in ipairs(lvl.pieces) do if p.source then src = p.start end end
  local first = lvl.nb[src][1]
  for q, p in ipairs(lvl.pieces) do
    if (p.tag == "adp" or p.tag == "elb") and st.pos[q] ~= 0 then
      local c = st.pos[q]
      if st.fixed[q] then
        if p.tag == "elb" and c ~= first then return true end
        if p.tag == "adp" then local ok = false; for _, b in ipairs(lvl.pieces) do if b.fixture and (lvl.nb[b.start][2] == c or lvl.nb[b.start][4] == c) then ok = true end end; if not ok then return true end end
      elseif not jet[c] then
        local boxed = true
        for d = 1, 4 do
          local fwd, back = lvl.nb[c][d], lvl.nb[c][({ 3, 4, 1, 2 })[d]]
          if not solid(fwd) and not solid(back) then boxed = false end
        end
        if boxed then return true end
      end
    end
  end
  -- широкий (скептик): муфта закреплена (вход ванны «под ноги»); фонтан заглушён, а переходник не в ванне и не над ней
  do
    local Q = {}
    for q, p in ipairs(lvl.pieces) do if p.tag then Q[p.tag] = q end end
    if Q.cpl and st.fixed[Q.cpl] then return true end
    if st.fixed[Q.elb] and not st.fixed[Q.adp] then
      local ax = (st.pos[Q.adp] - 1) % W + 1
      local sx = (src - 1) % W + 1
      if st.pos[Q.adp] == 0 or ax ~= sx then return true end
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
    "##....###",
    "##.....##",
    "####....#",
    "#####...#",
    "#####...#",
    "#####.###",
    "#########",
  },
  objects = {
    { kind = "source", at = { 6, 7 }, ports = { up = "N" } },
    { kind = "fixture", what = "bath", at = { 5, 4 }, ports = { right = "N" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 6, 3 }, ports = { down = "V", right = "V" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 4, 3 }, ports = { left = "V", right = "V" } },
    { kind = "fitting", what = "nipple", tag = "adp", at = { 5, 3 }, ports = { left = "V", right = "N" } },
    { kind = "lapidus", cells = { { 7, 6 }, { 7, 5 } }, head = 2 },
  },
}
