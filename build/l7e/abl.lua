-- build/l7e/abl.lua файл.lua — узкие абляции и контроли (фильтры ходов): решаем ли уровень и за сколько. Без ходов.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local Q = {}; for q, p in ipairs(lvl.pieces) do if p.tag then Q[p.tag] = q end; if p.what == "tee" then Q.tee = q end end
local base = lvl.nb[lvl.pieces[Q.tee].start][1]
local function xy(c) return R.xy(lvl, c) end
local function fountain(ns)
  local col = {}
  for _, j in ipairs(R.jets(lvl, ns)) do if j.dir == R.UP and not j.lapidus then for _, c in ipairs(j.cells) do col[c] = true end end end
  return col
end
local function held(ns)
  if ns.dead then return nil end
  local col = fountain(ns); local body = {}; for _, c in ipairs(ns.body) do body[c] = true end
  for q, p in ipairs(lvl.pieces) do local c = ns.pos[q]
    if p.movable and c ~= 0 and not ns.fixed[q] and col[c] and body[lvl.nb[c][1]] then return q end end
end
local function bodyHas(ns, f) if ns.dead then return false end for _, c in ipairs(ns.body) do local x, y = xy(c); if f(x, y) then return true end end end
local function pairNP(ns) return ns.pos[Q.nip] ~= 0 and ns.pos[Q.plug] ~= 0 and ns.asm[Q.nip] == ns.asm[Q.plug] and not ns.fixed[Q.nip] end
local function inCol(ns, q) local c = ns.pos[q]; return c ~= 0 and fountain(ns)[c] end
local filters = {
  { "А: держать можно только у верхушки (тело не выше ряда 3 — нет удержания)", function(l, st, ns) local q = held(ns); return not q or bodyHas(ns, function(x, y) return y <= 3 end) end },
  { "А: держать можно только у основания (тело касается ряда ≤ 3 — нет удержания)", function(l, st, ns) local q = held(ns); return not q or not bodyHas(ns, function(x, y) return y <= 3 end) end },
  { "А: держать можно только угольник", function(l, st, ns) local q = held(ns); return not q or q == Q.elb end },
  { "А: держать можно только пару (ниппель/заглушку)", function(l, st, ns) local q = held(ns); return not q or q ~= Q.elb end },
  { "А: Лапидус не поднимается фонтаном (тело не в столбе, пока не прикручен)", function(l, st, ns)
      if ns.dead then return true end
      local piece = R.occupancy and R.occupancy(ns) or nil
      local w = R.water(lvl, ns, piece or select(1, (function() local o = {} for q = 1, #ns.pos do if ns.pos[q] ~= 0 then o[ns.pos[q]] = q end end return o end)()))
      if w.headQ or w.heelQ then return true end
      local col = fountain(ns); return not bodyHas(ns, function(x, y) return col[R.idx(lvl, x, y)] end) end },
  { "А: угольник не вдавливают сверху (не входит в первую клетку фонтана из клетки над ней)", function(l, st, ns)
      local a, b = st.pos[Q.elb], ns.pos[Q.elb]
      return not (a ~= 0 and b == base and a == lvl.nb[base][1]) end },
  { "К: ниппель и заглушка никогда не свинчены до закрепления (входят порознь)", function(l, st, ns) return not pairNP(ns) end },
  { "К: пара свинчивается только на полу ряда 6 (не на полке и не в столбе)", function(l, st, ns)
      if not pairNP(ns) then return true end
      local _, y = xy(ns.pos[Q.nip]); return y == 6 end },
  { "К: без брандспойта (нет состояний с мокрым Лапидусом и свободным концом)", function(l, st, ns)
      if ns.dead then return true end
      local o = {} for q = 1, #ns.pos do if ns.pos[q] ~= 0 then o[ns.pos[q]] = q end end
      local w = R.water(lvl, ns, o)
      for _, j in ipairs(R.jets(lvl, ns)) do if j.lapidus then return false end end
      return true end },
  { "К: заглушка никогда не выше ряда 5 (не катается)", function(l, st, ns) local c = ns.pos[Q.plug]; if c == 0 then return true end local _, y = xy(c); return y >= 5 end },
  { "К: ниппель никогда не выше ряда 5", function(l, st, ns) local c = ns.pos[Q.nip]; if c == 0 then return true end local _, y = xy(c); return y >= 5 end },
  { "К: угольник никогда не выше ряда 3 (не под самым потолком)", function(l, st, ns) local c = ns.pos[Q.elb]; if c == 0 then return true end local _, y = xy(c); return y >= 3 end },
  { "К: Лапидус не заходит в правый ствол шахты (x=6, ряды 2–4)", function(l, st, ns) return not bodyHas(ns, function(x, y) return x == 6 and y <= 4 end) end },
  { "К: Лапидус не заходит на (2,5)", function(l, st, ns) return not bodyHas(ns, function(x, y) return x == 2 and y == 5 end) end },
  { "К: длина не больше 4", function(l, st, ns) return ns.dead or #ns.body <= 4 end },
}
for _, f in ipairs(filters) do
  local ok, G = pcall(SV.explore, lvl, 3000000, f[2])
  if not ok then print(f[1] .. " → ошибка фильтра: " .. tostring(G)) else
  local r = (G and G.firstWin) and ("РЕШАЕМ за " .. G.depth[G.firstWin]) or "нерешаем"
  print(string.format("%s → %s", f[1], r))
  if G then SV.freeGraph(G) end end
end
