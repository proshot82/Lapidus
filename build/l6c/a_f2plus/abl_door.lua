-- абляции РОЛИ для раскладок «гнездо — дверь» (кв. 6, направление A). Фильтры ходов filter(lvl, st, ns).
local function find(lvl)
  local sock, cpl, nip
  for q, p in ipairs(lvl.pieces) do
    if p.fixture then for d = 1, 4 do if p.ports[d] then sock = lvl.nb[p.start][d] end end end
    if p.tag == "cpl" then cpl = q elseif p.tag == "nip" then nip = q end
  end
  return sock, cpl, nip
end
local function col(lvl, c) return (c - 1) % lvl.W + 1 end
local function row(lvl, c) return math.floor((c - 1) / lvl.W) + 1 end
-- 1) муфта не проходит сквозь гнездо: запрещён ход, после которого муфта оказалась под гнездом, придя сверху
local function noPass(lvl, st, ns)
  local sock, cpl = find(lvl)
  local a, b = st.pos[cpl], ns.pos[cpl]
  if a == 0 or b == 0 then return true end
  if row(lvl, a) <= row(lvl, sock) and col(lvl, b) == col(lvl, sock) and row(lvl, b) > row(lvl, sock) then return false end
  return true
end
-- 2) (справочно, не роль ключевого приёма) развернуться под колонкой нельзя: Лапидусу запрещено занимать клетку гнезда
local function noTurn(lvl, st, ns)
  local sock = find(lvl)
  for _, c in ipairs(ns.body) do if c == sock then return false end end
  return true
end
-- 3) ногами дверь не закрывают: запрещено вставить ниппель ходом ног
local function noHeelClose(lvl, st, ns)
  local _, _, nip = find(lvl)
  if ns.fixed[nip] and not st.fixed[nip] and st.body[1] ~= ns.body[1] then return false end
  return true
end
return {
  { name = "без муфты", remove = "cpl" },
  { name = "без ниппеля", remove = "nip" },
  { name = "муфта не проходит сквозь гнездо", filter = noPass },
  { name = "ногами дверь не закрыть", filter = noHeelClose },
}
