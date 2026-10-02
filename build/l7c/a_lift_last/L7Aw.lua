-- Квартира 7 «Дали напор» — кандидат ядра, направление A «лифт, который глушат последним»
-- (build/l7c/a_lift_last, раскладка b10, 28.09.2026). Решение здесь не пишется.
-- Стояк течёт вверх фонтаном (напор 3); вход ванны смотрит прямо в струю. Фонтан держит на весу всё, что в него
-- попало, поэтому сам стояк глушится только сбоку. На фонтане с самого начала пляшет лишняя муфта, на антресоли —
-- переходник и угольник. Ложный план: «сначала заткнуть течь» — угольником сразу или муфтой сверху.
-- Ловушки (общими словами): муфта, вкрученная в ванну, ломает чётность резьбы; заглушённый раньше времени фонтан
-- больше ничего не поднимет; лишнюю муфту, скормленную фонтану не вовремя, уже не достать; переходник, сбитый
-- в карман, не вернуть.

-- Видимый проигрыш (САМЫЙ ШИРОКИЙ, скептик x; для замера, не для игры): нужная деталь (переходник, угольник) зажата так, что её уже не сдвинуть
-- ни в одну сторону (стоит на твёрдом; с каждой стороны либо упор, либо толкать некому — стена или закреплённое)
-- и она не в струе; либо нужная деталь закреплена не на своём месте (угольник — только в основании фонтана,
-- переходник — только у ванны). Муфту в ванне и свинченные пары не помечает — это «ага».
local function visibleLoss(lvl, st)
  local R = require("core.rules")
  local piece = {}
  for q = 1, #st.pos do if st.pos[q] ~= 0 then piece[st.pos[q]] = q end end
  local function solid(c) if c == 0 or lvl.cell[c] == 1 then return true end local r = piece[c]; return r and st.fixed[r] end
  local jet = {}
  for _, j in ipairs(R.jets(lvl, st)) do for _, c in ipairs(j.cells) do jet[c] = true end end
  local src
  for _, p in ipairs(lvl.pieces) do if p.source then src = p.start end end
  local first = lvl.nb[src][1]
  for q, p in ipairs(lvl.pieces) do
    if (p.tag == "adp" or p.tag == "elb") and st.pos[q] ~= 0 then
      local c = st.pos[q]
      if st.fixed[q] then
        if p.tag == "elb" and c ~= first then return true end
        if p.tag == "adp" then
          local ok = false
          for _, b in ipairs(lvl.pieces) do if b.fixture and (lvl.nb[b.start][2] == c or lvl.nb[b.start][4] == c) then ok = true end end
          if not ok then return true end
        end
      elseif not jet[c] and solid(lvl.nb[c][3]) then
        local boxed = true
        for d = 1, 4 do
          local fwd, back = lvl.nb[c][d], lvl.nb[c][({ 3, 4, 1, 2 })[d]]
          if not solid(fwd) and not solid(back) then boxed = false end
        end
        if boxed then return true end
      end
    end
  end
  -- широкий (скептик): муфта закреплена (в ванне «под ноги» или где-то ещё) или свинчена с переходником;
  -- фонтан заглушён, а переходник не в ванне и не в шахте стояка
  local W = lvl.W
  local Q = {}
  for q, p in ipairs(lvl.pieces) do if p.tag then Q[p.tag] = q end end
  if st.fixed[Q.cpl] then return true end
  -- самый широкий (x): незакреплённый переходник упал правее шахты стояка
  if st.pos[Q.adp] ~= 0 and not st.fixed[Q.adp] and (st.pos[Q.adp] - 1) % W > (src - 1) % W then return true end
  if st.pos[Q.cpl] ~= 0 and st.pos[Q.adp] ~= 0 and st.asm[Q.cpl] == st.asm[Q.adp] then return true end
  if st.fixed[Q.elb] and not st.fixed[Q.adp] then
    if st.pos[Q.adp] == 0 or (st.pos[Q.adp] - 1) % W ~= (src - 1) % W then return true end
  end
  return false
end

-- Абляции ролей (фильтры ходов): каждая запрещает одну роль фонтана или деталей — уровень становится нерешаемым.
local function tags(lvl) local Q = {}; for q, p in ipairs(lvl.pieces) do if p.tag then Q[p.tag] = q end end; return Q end
local function srcXY(lvl) for _, p in ipairs(lvl.pieces) do if p.source then return (p.start - 1) % lvl.W + 1, math.floor((p.start - 1) / lvl.W) + 1 end end end
local function XY(lvl, c) return (c - 1) % lvl.W + 1, math.floor((c - 1) / lvl.W) + 1 end
-- опора струи вверх: клетки столба и клетка над его верхушкой
local function onJet(lvl, st, c, inside)
  local R = require("core.rules")
  for _, j in ipairs(R.jets(lvl, st)) do
    if j.dir == 1 and #j.cells > 0 then
      for _, t in ipairs(j.cells) do if t == c then return true end end
      if not inside and lvl.nb[j.cells[#j.cells]][1] == c then return true end
    end
  end
  return false
end
-- фонтан не глотает муфту: муфта не бывает внутри действующей струи
local function noSwallow(lvl, st, ns)
  local Q = tags(lvl)
  local c = ns.pos[Q.cpl]
  return c == 0 or not onJet(lvl, ns, c, true)
end
-- фонтан не возит переходник: незакреплённый переходник не бывает на опоре струи
local function noRideAdp(lvl, st, ns)
  local Q = tags(lvl)
  local c = ns.pos[Q.adp]
  return c == 0 or ns.fixed[Q.adp] or not onJet(lvl, ns, c, false)
end
-- фонтан не возит угольник: незакреплённый угольник не бывает на опоре струи
local function noRideElb(lvl, st, ns)
  local Q = tags(lvl)
  local c = ns.pos[Q.elb]
  return c == 0 or ns.fixed[Q.elb] or not onJet(lvl, ns, c, false)
end
-- течь глушат первой: переходник не закрепить, пока угольник не закреплён
local function capFirst(lvl, st, ns)
  local Q = tags(lvl)
  return not (ns.fixed[Q.adp] and not ns.fixed[Q.elb])
end
-- муфту некуда отложить: муфта не бывает правее стояка
local function noPark(lvl, st, ns)
  local Q = tags(lvl); local sx = srcXY(lvl)
  local c = ns.pos[Q.cpl]; if c == 0 then return true end
  return (XY(lvl, c)) <= sx
end

return {
  id = 7, flat = 7, name = "Дали напор",
  length = { 2, 5 }, pressure = 3, tile = "mint",
  target = { moves = { 20, 45 }, states = 100000, dead = 50, fb = 3 },
  visibleLoss = visibleLoss,
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
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 6, 3 }, ports = { left = "V", right = "V" } },
    { kind = "fitting", what = "nipple", tag = "adp", at = { 4, 3 }, ports = { left = "V", right = "N" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 5, 3 }, ports = { down = "V", right = "V" } },
    { kind = "lapidus", cells = { { 7, 6 }, { 7, 5 } }, head = 2 },
  },
  ablations = {
    { name = "без угольника", remove = "elb" },
    { name = "фонтан не глотает муфту", filter = noSwallow },
    { name = "фонтан не возит переходник", filter = noRideAdp },
    { name = "фонтан не возит угольник", filter = noRideElb },
    { name = "течь глушат первой", filter = capFirst },
    { name = "муфту некуда отложить", filter = noPark },
  },
  texts = {
    request = "Дали напор. Бьёт в потолок, в ванну не попадает.",
    hints = {
      "Фонтан глушат последним: пока бьёт, он и лифт для переходника, и глотка для лишней муфты.",
      "Ваш звонок очень важен для нас. Проверяем, не вкрутили ли вы в ванну муфту вместо переходника.",
      "Мастер выехал. Стояк он глушит сбоку: кто глушит сверху, тот потом сушит усы.",
    },
  },
}
