-- abl_d.lua — абляции РОЛИ приёма для кандидатов направления D (фильтры ходов filter(lvl, st, ns)).
local M = {}
local function tagq(lvl, tag) for q, p in ipairs(lvl.pieces) do if p.tag == tag then return q end end end
local function row(lvl, c) return math.floor((c - 1) / lvl.W) + 1 end
-- «кран запрещён»: муфту (C) нельзя поднимать — разворот в её трубе недоступен
function M.noLiftC(lvl, st, ns)
  local q = tagq(lvl, "C")
  local a, b = st.pos[q], ns.pos[q]
  if a ~= 0 and b ~= 0 and row(lvl, b) < row(lvl, a) then return false end
  return true
end
-- «в кармане не развернуться»: Лапидусу нельзя спускаться в карман под муфтой, пока она не закреплена
function M.noPocket(lvl, st, ns)
  local q = tagq(lvl, "C")
  if ns.fixed[q] then return true end
  local cx = (lvl.pieces[q].start - 1) % lvl.W + 1
  local cy = row(lvl, lvl.pieces[q].start)
  for _, c in ipairs(ns.body) do
    local x, y = (c - 1) % lvl.W + 1, row(lvl, c)
    if x == cx and y > cy + 1 then return false end
  end
  return true
end
-- «муфту толкают только головой»: запрещён ход ногами, сдвигающий муфту
function M.noHeelPushC(lvl, st, ns)
  local q = tagq(lvl, "C")
  if st.pos[q] == ns.pos[q] then return true end
  -- ноги — первая клетка тела; если они сдвинулись в клетку, где была муфта, — это толчок ногами
  if ns.body[1] == st.pos[q] and st.body[1] ~= ns.body[1] then return false end
  return true
end
-- «ниппель поднимает только голова» / «только ноги»
function M.nipByHeelOnly(lvl, st, ns)
  local q = tagq(lvl, "B")
  if st.pos[q] == ns.pos[q] or st.pos[q] == 0 or ns.pos[q] == 0 then return true end
  if ns.body[#ns.body] == st.pos[q] then return false end
  return true
end
function M.nipByHeadOnly(lvl, st, ns)
  local q = tagq(lvl, "B")
  if st.pos[q] == ns.pos[q] or st.pos[q] == 0 or ns.pos[q] == 0 then return true end
  if ns.body[1] == st.pos[q] then return false end
  return true
end
return M
