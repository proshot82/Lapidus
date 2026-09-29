-- build/l2c/zones.lua файл.lua — состояния кв. 2 по зонам (где Лапидус и за что держится): живые / скрытые / видимые,
-- и метрики, которых нет в check.lua для уровня без деталей:
--   события пути = прикрутил/открутил конец или упал (смена опоры); прогулка = ходов пути подряд без событий;
--   вынужденные = подряд шагов пути, где безопасный (живой) ход ровно один;
--   мерка «знатока» (для сведения): видимо проиграно ещё и то, из чего ЛЮБОЙ следующий ход ведёт в тупик.
-- Решений не печатает (только номера шагов и счётчики).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local function lost(st) return def.visibleLoss and def.visibleLoss(lvl, st) or false end
local W = lvl.W
local function xy(c) return (c - 1) % W + 1, math.floor((c - 1) / W) + 1 end
local st = {}
for i = 1, G.n do st[i] = R.decode(lvl, G.keys[i]) end
local function anchors(s)
  if s.dead then return "смыт" end
  local occ = R.occupancy(s)
  local h = R.endScrew(lvl, s, occ, "head")
  local f = R.endScrew(lvl, s, occ, "heel")
  local t = {}
  if f then local p = lvl.pieces[f]; t[#t + 1] = "ноги:" .. (p.tag or p.kind) .. "(" .. p.x .. "," .. p.y .. ")" end
  if h then local p = lvl.pieces[h]; t[#t + 1] = "голова:" .. (p.tag or p.kind) .. "(" .. p.x .. "," .. p.y .. ")" end
  return #t > 0 and table.concat(t, " ") or "-"
end
-- зона: самая верхняя строка тела и признак «на крючьях»
local function zone(s)
  if s.dead then return "смыт" end
  local a = anchors(s)
  if a ~= "-" then return "висит/прикручен" end
  local miny, maxy, minx, maxx = 99, 0, 99, 0
  for _, c in ipairs(s.body) do local x, y = xy(c); miny = math.min(miny, y); maxy = math.max(maxy, y); minx = math.min(minx, x); maxx = math.max(maxx, x) end
  if def.zoneOf then return def.zoneOf(lvl, s, minx, maxx, miny, maxy) end
  return string.format("строки %d-%d", miny, maxy)
end
local agg, order = {}, {}
local hid, live, vis = 0, 0, 0
for i = 1, G.n do
  local z = zone(st[i])
  if not agg[z] then agg[z] = { 0, 0, 0 }; order[#order + 1] = z end
  if G.flag[i] == 2 then agg[z][3] = agg[z][3] + 1
  elseif good[i] == 1 then agg[z][1] = agg[z][1] + 1; live = live + 1
  elseif lost(st[i]) then agg[z][3] = agg[z][3] + 1; vis = vis + 1
  else agg[z][2] = agg[z][2] + 1; hid = hid + 1 end
end
print("зона                              живых скрытых видимых/смыт")
for _, z in ipairs(order) do print(string.format("%-32s %6d %7d %7d", z, agg[z][1], agg[z][2], agg[z][3])) end
-- мерка знатока: скрытое состояние, все ходы из которого ведут в тупик/смыв и которое... (однократно)
local hidK = 0
for i = 1, G.n do
  if G.flag[i] ~= 2 and good[i] ~= 1 and not lost(st[i]) then
    -- «вскрывается следующим ходом»: из состояния нет ни одного хода в скрытое (только видимое/смыв/нет ходов)
    local anyHidden = false
    for e = G.eStart.p[i - 1], G.eStart.p[i] - 1 do
      local j = G.edges.p[e]
      if G.flag[j] ~= 2 and good[j] ~= 1 and not lost(st[j]) and j ~= i then anyHidden = true break end
    end
    if anyHidden then hidK = hidK + 1 end
  end
end
print(string.format("по мерке новичка: скрытых %d, живых %d → %.0f %%; «знаток» (минус тупики, вскрывающиеся следующим ходом): скрытых %d → %.0f %%",
  hid, live, 100 * hid / math.max(1, hid + live), hidK, 100 * hidK / math.max(1, hidK + live)))
-- путь: события, прогулка, вынужденные
local path, x = {}, G.firstWin
while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
table.insert(path, 1, 1)
local ev, streak, maxStreak, forcedRun, maxForced = {}, 0, 0, 0, 0
local evCount = 0
for k = 1, #path - 1 do
  local a, b = st[path[k]], st[path[k + 1]]
  local isEv = anchors(a) ~= anchors(b)
  -- падение: тело сместилось вниз целиком сверх хода (грубо: разница клеток больше одной)
  if not isEv then
    local same = 0
    local set = {}
    for _, c in ipairs(a.body) do set[c] = true end
    for _, c in ipairs(b.body) do if set[c] then same = same + 1 end end
    if same < math.min(#a.body, #b.body) - 1 then isEv = true end
  end
  if isEv then evCount = evCount + 1; streak = 0 else streak = streak + 1; if streak > maxStreak then maxStreak = streak end end
  local safe = 0
  for e = G.eStart.p[path[k] - 1], G.eStart.p[path[k]] - 1 do if good[G.edges.p[e]] == 1 then safe = safe + 1 end end
  if safe == 1 then forcedRun = forcedRun + 1; if forcedRun > maxForced then maxForced = forcedRun end else forcedRun = 0 end
end
print(string.format("путь %d ходов: событий (прикрутил/открутил/упал) %d, прогулка max %d, вынужденных подряд max %d", #path - 1, evCount, maxStreak, maxForced))
SV.freeGraph(G); require("ffi").C.free(good)
