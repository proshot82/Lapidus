-- abl_m.lua — абляции РОЛИ ключевого приёма для семейства M (кв. 6, направление C). Фильтры ходов filter(lvl, st, ns).
local function cells(lvl)
  local srcCatch, stubCatch, stubCol
  for q, p in ipairs(lvl.pieces) do
    if p.source and p.ports[1] then srcCatch = lvl.nb[p.start][1] end
    if p.kind == "stub" and p.ports[1] then stubCatch = lvl.nb[p.start][1]; stubCol = (p.start - 1) % lvl.W + 1 end
  end
  return srcCatch, stubCatch, stubCol
end
local function fixedAt(st, c)
  for k = 1, #st.pos do if st.pos[k] == c and st.fixed[k] then return k end end
  return nil
end
-- 1) «сначала лестница»: стояк можно закрыть муфтой только после того, как на отводе уже стоит ступенька
local function ladderFirst(lvl, st, ns)
  local srcCatch, stubCatch = cells(lvl)
  if fixedAt(ns, srcCatch) and not fixedAt(st, srcCatch) and not fixedAt(ns, stubCatch) then return false end
  return true
end
-- 2) «ступенька не держит»: по ступеньке на отводе нельзя подняться в дальний колодец
--    (запрещено занимать клетки дальнего колодца выше нижнего яруса, пока там не было Лапидуса без ступеньки —
--    без ступеньки туда и так не забраться)
local function noClimb(lvl, st, ns)
  local _, stubCatch, stubCol = cells(lvl)
  local topRow = math.floor((stubCatch - 1) / lvl.W) + 1 - 2 -- ряд над двухэтажным нижним ярусом
  for _, c in ipairs(ns.body) do
    local x, y = (c - 1) % lvl.W + 1, math.floor((c - 1) / lvl.W) + 1
    if x == stubCol and y <= topRow then return false end
  end
  return true
end
-- 3) «ниппель — только из ближнего колодца»: ниппель нельзя толкать к гнезду колонки со стороны дальнего колодца
local function nearOnly(lvl, st, ns)
  local nip, sock
  for q, p in ipairs(lvl.pieces) do
    if p.tag == "B" then nip = q end
    if p.fixture then for d = 1, 4 do if p.ports[d] then sock = lvl.nb[p.start][d] end end end
  end
  local a, b = st.pos[nip], ns.pos[nip]
  if a ~= 0 and b ~= 0 and a ~= b then
    local sx, ax, bx = (sock - 1) % lvl.W + 1, (a - 1) % lvl.W + 1, (b - 1) % lvl.W + 1
    if ax > sx and bx < ax then return false end
  end
  return true
end
return {
  { name = "сначала лестница, потом стояк", filter = ladderFirst },
  { name = "по ступеньке не подняться", filter = noClimb },
  { name = "ниппель только из ближнего колодца", filter = nearOnly },
}
