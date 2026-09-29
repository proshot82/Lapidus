-- build/l7v_c/abl.lua [имя ...] — свои фильтры ходов (абляции роли и контроли) для кандидата:
-- решаем ли уровень при запрете приёма, и длина кратчайшего решения с этим запретом. Решения не печатаются.
local M = dofile("build/l7v_c/lib.lua")
local R = M.R
local def, lvl = M.load()
local function find()
  local t = {}
  for q, p in ipairs(lvl.pieces) do if p.source then t.src = q elseif p.fixture then t.fix = q end; if p.tag then t[p.tag] = q end end
  return t
end
local k = find()
local sx, sy = R.xy(lvl, lvl.pieces[k.src].start)
local function col(c) return c ~= 0 and (R.xy(lvl, c)) == sx end
local function row(c) local _, y = R.xy(lvl, c); return y end
local function bodyAt(ns) local t = {}; for _, b in ipairs(ns.body) do t[b] = true end; return t end
local F = {}
-- абляции-кандидаты
F.teeNoRow7 = { desc = "тройник никогда не в коридоре (ряд 7) — без «очереди через жёлоб»",
  f = function(lvl, st, ns) local c = ns.pos[k.tee]; return not (c ~= 0 and row(c) == 7) end }
F.lapNoFoot = { desc = "тело Лапидуса не в столбе на y≥6 до закрепления ниппеля (2-я половина noCrossing автора)",
  f = function(lvl, st, ns)
    if ns.fixed[k.nip] then return true end
    for _, c in ipairs(ns.body) do if col(c) and row(c) >= sy - lvl.R then return false end end
    return true end }
F.teeStays = { desc = "тройник, войдя в столб, его не покидает (1-я половина noCrossing автора)",
  f = function(lvl, st, ns) return not (col(st.pos[k.tee]) and not st.fixed[k.tee] and not col(ns.pos[k.tee])) end }
F.noHold = { desc = "деталь не удерживается в клетке струи телом Лапидуса сверху",
  f = function(lvl, st, ns)
    local b = bodyAt(ns)
    for q, p in ipairs(lvl.pieces) do
      local c = ns.pos[q]
      if p.movable and c ~= 0 and not ns.fixed[q] and col(c) and row(c) >= sy - lvl.R and b[lvl.nb[c][1]] then return false end
    end
    return true end }
F.noCrane = { desc = "Лапидус не толкает деталь вверх (кран из кв. 6)",
  f = function(lvl, st, ns)
    local b = bodyAt(ns)
    for q, p in ipairs(lvl.pieces) do
      local c0, c1 = st.pos[q], ns.pos[q]
      if p.movable and c0 ~= 0 and c1 ~= 0 and c1 == lvl.nb[c0][1] and b[c0] then return false end
    end
    return true end }
F.noShelf = { desc = "деталь не лежит на теле Лапидуса в столбе (полка)",
  f = function(lvl, st, ns)
    local b = bodyAt(ns)
    for q, p in ipairs(lvl.pieces) do
      local c = ns.pos[q]
      if p.movable and c ~= 0 and not ns.fixed[q] and col(c) and b[lvl.nb[c][3]] then return false end
    end
    return true end }
F.noLapColumnEarly = { desc = "тело Лапидуса не в столбе (x стояка, y≥5) до закрепления ниппеля",
  f = function(lvl, st, ns)
    if ns.fixed[k.nip] then return true end
    for _, c in ipairs(ns.body) do if col(c) and row(c) >= 5 then return false end end
    return true end }
-- контроли (должны остаться решаемыми)
F.ctlPlugStays = { desc = "КОНТРОЛЬ: заглушка, войдя в столб, его не покидает",
  f = function(lvl, st, ns) return not (col(st.pos[k.plug]) and not st.fixed[k.plug] and not col(ns.pos[k.plug])) end }
F.ctlNipLast = { desc = "КОНТРОЛЬ: ниппель не сдвигается, пока заглушка не в столбе",
  f = function(lvl, st, ns) return col(ns.pos[k.plug]) or ns.fixed[k.plug] or ns.pos[k.nip] == lvl.pieces[k.nip].start end }
F.ctlNoTee75 = { desc = "КОНТРОЛЬ: тройник никогда не стоит на стенке (7,5)",
  f = function(lvl, st, ns) return ns.pos[k.tee] ~= R.idx(lvl, 7, 5) end }
F.ctlNoLapCorner = { desc = "КОНТРОЛЬ: Лапидус не заходит в (4,6) головой",
  f = function(lvl, st, ns) return ns.body[#ns.body] ~= R.idx(lvl, 4, 6) end }
local names = {}
if #arg > 0 then for _, a in ipairs(arg) do names[#names + 1] = a end else for n in pairs(F) do names[#names + 1] = n end table.sort(names) end
for _, name in ipairs(names) do
  local fl = assert(F[name], "нет фильтра " .. name)
  local G = M.SV.explore(lvl, 3000000, fl.f)
  if not G then print(name .. ": CAP") else
    if G.firstWin then
      -- число кратчайших решений и ширина в отфильтрованном графе
      local cnt = { [1] = 1 }
      local ES, E = G.eStart.p, G.edges.p
      for i = 1, G.n do
        local c = cnt[i]
        if c and G.flag[i] == 0 then for e = ES[i - 1], ES[i] - 1 do local j = E[e]; if G.depth[j] == G.depth[i] + 1 then cnt[j] = (cnt[j] or 0) + c end end end
      end
      local total = 0
      for i = 1, G.n do if G.flag[i] == 1 and G.depth[i] == G.depth[G.firstWin] then total = total + (cnt[i] or 0) end end
      print(string.format("%-18s РЕШАЕМ: кратчайшее %d ходов, кратчайших %d, состояний %d — %s", name, G.depth[G.firstWin], total, G.n, fl.desc))
    else print(string.format("%-18s нерешаем (состояний %d) — %s", name, G.n, fl.desc)) end
    M.SV.freeGraph(G)
  end
end
