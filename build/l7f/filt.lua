-- build/l7f/filt.lua — узкие фильтры ходов (абляции роли и контроли) для кандидатов кв. 7, раунд 4.
-- Фильтр получает (lvl, st, ns) и возвращает false, если ход запрещён (см. solver/solve.lua, M.explore).
local R = require("core.rules")
local F = {}
local function find(lvl, what) for q, p in ipairs(lvl.pieces) do if p.what == what then return q end end end
local function row(lvl, c) return math.floor((c - 1) / lvl.W) + 1 end
-- клетки столба фонтана (струи вверх не от Лапидуса) и клетка над верхушкой каждого столба
local function fountain(lvl, ns)
  local col, top = {}, {}
  for _, j in ipairs(R.jets(lvl, ns)) do
    if j.dir == R.UP and not j.lapidus and #j.cells > 0 then
      for _, c in ipairs(j.cells) do col[c] = true end
      local t = lvl.nb[j.cells[#j.cells]][R.UP]; if t ~= 0 then top[t] = true end
    end
  end
  return col, top
end
local function anchored(lvl, ns)
  local occ = {}
  for q = 1, #ns.pos do if ns.pos[q] ~= 0 then occ[ns.pos[q]] = q end end
  local w = R.water(lvl, ns, occ)
  return w.headQ or w.heelQ
end
-- «Столб не поднимает Лапидуса»: неприкрученный Лапидус не бывает в клетках столба.
function F.noLapRide(lvl, st, ns)
  if ns.dead then return true end
  if anchored(lvl, ns) then return true end
  local col = fountain(lvl, ns)
  for _, c in ipairs(ns.body) do if col[c] then return false end end
  return true
end
-- «Деталь в столбе не вдавить сверху»: незакреплённая деталь в клетке столба (или над верхушкой), а прямо над ней — тело Лапидуса.
function F.noPushDown(lvl, st, ns)
  if ns.dead then return true end
  local col, top = fountain(lvl, ns)
  local body = {}
  for _, c in ipairs(ns.body) do body[c] = true end
  for q, p in ipairs(lvl.pieces) do
    local c = ns.pos[q]
    if p.movable and c ~= 0 and not ns.fixed[q] and (col[c] or top[c]) and body[lvl.nb[c][R.UP]] then return false end
  end
  return true
end
-- «Фонтан не держит деталь на весу»: незакреплённая деталь не бывает на клетке над верхушкой столба и в столбе.
function F.noHover(lvl, st, ns)
  if ns.dead then return true end
  local col, top = fountain(lvl, ns)
  for q, p in ipairs(lvl.pieces) do
    local c = ns.pos[q]
    if p.movable and c ~= 0 and not ns.fixed[q] and (col[c] or top[c]) then return false end
  end
  return true
end
-- Контроль «пара не свинчивается на лету»: ниппель и угольник не бывают одной незакреплённой сборкой.
function F.noPair(lvl, st, ns)
  if ns.dead then return true end
  local a, b = find(lvl, "nipple"), find(lvl, "elbow")
  if ns.pos[a] ~= 0 and ns.pos[b] ~= 0 and not ns.fixed[a] and ns.asm[a] == ns.asm[b] then return false end
  return true
end
-- Контроль «угольник не бывает на нижнем полу» (ряд H−1), кроме как закреплённым.
function F.elbowStaysUp(lvl, st, ns)
  if ns.dead then return true end
  local q = find(lvl, "elbow"); local c = ns.pos[q]
  return c == 0 or ns.fixed[q] or row(lvl, c) < lvl.H - 1
end
-- Контроль «ниппель не бывает на нижнем полу» (нижний ряд поля без стен — ряд H−1).
function F.nipStaysUp(lvl, st, ns)
  if ns.dead then return true end
  local q = find(lvl, "nipple"); local c = ns.pos[q]
  return c == 0 or ns.fixed[q] or row(lvl, c) < lvl.H - 1
end
-- «Струя не поднимает тело Лапидуса целиком» (узко, по трассе устаканивания; формулировка скептика build/l7v_g):
-- запрещён ход, при устаканивании которого всё тело сдвинулось на клетку вверх.
local function trace(lvl, st, ns)
  local k = R.key(ns)
  for m = 1, 8 do
    local mv = R.MOVES[m]; local tr = {}
    local s2 = R.move(lvl, st, mv.which, mv.dir, tr)
    if s2 and R.key(s2) == k then return tr end
  end
end
function F.lapLifted(lvl, st, ns)
  if ns.dead then return true end
  local tr = trace(lvl, st, ns); if not tr then return true end
  for i = 2, #tr do
    if tr[i].kind == "settle" then
      local a, b = tr[i-1].state.body, tr[i].state.body
      local up = (#a == #b)
      if up then for j = 1, #a do if b[j] ~= a[j] - lvl.W then up = false break end end end
      if up then return false end
    end
  end
  return true
end
return F
