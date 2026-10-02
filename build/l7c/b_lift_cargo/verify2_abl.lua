-- verify2_abl.lua файл.lua — абляции роли и контроли (кв. 7, p2b), без решений и кадров:
--  1) что именно режут авторские фильтры: сколько переходов графа и сколько состояний кратчайшего пути;
--  2) зеркальные и соседние контроли (должны оставаться решаемыми — иначе абляция режет не приём, а всё подряд);
--  3) обходные маршруты: есть ли живые состояния у альтернативных планов (пара «заглушка+переходник» собрана вне
--     столба, заглушка прямо на тройнике, тройник справа, Лапидус не поднимает стопку сам).
package.path = "./?.lua;" .. package.path
local L = dofile("build/l7c/b_lift_cargo/verify2_lib.lua")
local R, SV = L.R, L.SV
local def = dofile(arg[1])
local lvl, G, good = L.graph(def)
local k = L.keys(lvl)
local sx, sy = k.sx, k.sy
local path = L.path(G)
local S = {}
for i = 1, G.n do if G.flag[i] ~= 2 then S[i] = R.decode(lvl, G.keys[i]) end end
local function inCol(c) return c ~= 0 and (R.xy(lvl, c)) == sx end

print("1) что режут авторские фильтры (на полном графе исходного уровня):")
for _, ab in ipairs(def.ablations or {}) do
  if ab.filter then
    local cut, onPath = 0, 0
    for i = 1, G.n do
      if G.flag[i] == 0 then
        for e = G.eStart.p[i - 1], G.eStart.p[i] - 1 do
          local j = G.edges.p[e]
          if S[j] and not ab.filter(lvl, S[i], S[j]) then cut = cut + 1 end
        end
      end
    end
    for idx = 2, #path do if not ab.filter(lvl, S[path[idx - 1]], S[path[idx]]) then onPath = onPath + 1 end end
    print(string.format("   %s: запрещено переходов %d; на кратчайшем пути запрещено %d из %d ходов", ab.name, cut, onPath, #path - 1))
  end
end

local function solvable(filter, mut)
  local d2 = SV.deepcopy(def); d2.ablations = nil
  if mut then mut(d2) end
  local l2 = R.compile(d2)
  local G2 = SV.explore(l2, 3000000, filter)
  local ok = G2 and G2.firstWin ~= nil
  local mv = ok and G2.depth[G2.firstWin] or nil
  local n = G2 and G2.n or -1
  SV.freeGraph(G2)
  return ok, mv, n
end
local controls = {
  { "тройник не едет в столб раньше заглушки (зеркало абляции)", function(l, st, ns)
      return not (inCol(ns.pos[k.tee]) and not ns.fixed[k.tee] and not inCol(ns.pos[k.plug])) end },
  { "тройник не едет в столб раньше переходника (зеркало абляции)", function(l, st, ns)
      return not (inCol(ns.pos[k.tee]) and not ns.fixed[k.tee] and not inCol(ns.pos[k.adp])) end },
  { "ниппель не в основании, пока тройник вне столба", function(l, st, ns)
      return not (ns.fixed[k.nip] and not inCol(ns.pos[k.tee])) end },
  { "заглушка и переходник не бывают левее столба", function(l, st, ns)
      for _, q in ipairs({ k.plug, k.adp }) do local c = ns.pos[q]; if c ~= 0 and (R.xy(l, c)) < sx then return false end end
      return true end },
  { "тройник не бывает правее столба", function(l, st, ns)
      local c = ns.pos[k.tee]; return not (c ~= 0 and not ns.fixed[k.tee] and (R.xy(l, c)) > sx) end },
  { "заглушка и переходник не свинчиваются вне столба", function(l, st, ns)
      return not (L.screwedOn(l, ns, k.plug, k.adp) and not inCol(ns.pos[k.plug])) end },
  { "Лапидус не поднимает детали в шахте выше клетки над струёй (стопку держит только струя)", function(l, st, ns)
      -- запрещено: незакреплённая деталь выше, чем её может держать струя с учётом стопки под ней
      local base = l.pieces[k.src].start
      while true do local u = l.nb[base][R.UP]; local q = nil
        for qq = 1, #ns.pos do if ns.pos[qq] == u and ns.fixed[qq] then q = qq end end
        if q then base = u else break end end
      local _, by = R.xy(l, base)
      for q, p in ipairs(l.pieces) do
        local c = ns.pos[q]
        if p.movable and c ~= 0 and not ns.fixed[q] and inCol(c) then
          local _, cy = R.xy(l, c)
          local under = 0
          for q2, p2 in ipairs(l.pieces) do local c2 = ns.pos[q2]; if p2.movable and c2 ~= 0 and not ns.fixed[q2] and inCol(c2) and c2 > c then under = under + 1 end end
          if cy < by - l.R - 1 - under then return false end
        end
      end
      return true end },
}
print("2) контроли:")
for _, c in ipairs(controls) do
  local ok, mv, n = solvable(c[2])
  print(string.format("   %s: %s (состояний %d)", c[1], ok and ("решаем за " .. mv .. " ходов") or "НЕРЕШАЕМ", n))
end
local ok5, mv5 = solvable(nil, function(d) d.length = { 2, 5 } end)
print(string.format("   длина 2–5: %s", ok5 and ("решаем за " .. mv5 .. " ходов") or "НЕРЕШАЕМ"))
local ok3, mv3, n3 = solvable(nil, function(d) d.pressure = 3 end)
print(string.format("   напор 3 (как в §6): %s (состояний %d)", ok3 and ("решаем за " .. mv3 .. " ходов") or "НЕРЕШАЕМ", n3))
local ok1, mv1, n1 = solvable(nil, function(d) d.pressure = 1 end)
print(string.format("   напор 1: %s (состояний %d)", ok1 and ("решаем за " .. mv1 .. " ходов") or "НЕРЕШАЕМ", n1))

print("3) обходные планы (живые состояния = план ещё выигрывает):")
local routes = {
  { "заглушка с переходником свинчены вне столба", function(st) return L.screwedOn(lvl, st, k.plug, k.adp) and not inCol(st.pos[k.plug]) end },
  { "заглушка свинчена прямо на тройник", function(st) return L.screwedOn(lvl, st, k.plug, k.tee) end },
  { "тройник свинчен сверху на переходник", function(st) return L.screwedOn(lvl, st, k.tee, k.adp) end },
  { "тройник правее столба", function(st) local c = st.pos[k.tee]; return not st.fixed[k.tee] and c ~= 0 and (R.xy(lvl, c)) > sx end },
  { "переходник левее столба", function(st) local c = st.pos[k.adp]; return c ~= 0 and (R.xy(lvl, c)) < sx end },
  { "заглушка левее столба", function(st) local c = st.pos[k.plug]; return c ~= 0 and (R.xy(lvl, c)) < sx end },
  { "тройник в левой яме", function(st) local c = st.pos[k.tee]; local x, y = R.xy(lvl, c); return x < sx and y == sy - 1 end },
}
for _, r in ipairs(routes) do
  local n, live = 0, 0
  for i = 1, G.n do if G.flag[i] == 0 and r[2](S[i]) then n = n + 1; if good[i] == 1 then live = live + 1 end end end
  print(string.format("   %s: состояний %d, живых %d", r[1], n, live))
end
SV.freeGraph(G); require("ffi").C.free(good)
