-- build/l1c/hint1.lua файл.lua — ошибка из подсказки №1 («прикрутите сначала «не тот» конец»):
-- спуститься в шахту, не повиснув ногами на крюке, — то есть оказаться целиком ниже коридора (ни одной клетки
-- в ряду 2) ногами вперёд. Проверяет конкретными состояниями: сколько таких состояний, живых среди них (должно быть 0),
-- видимых по мерке файла (должно быть 0), как рано ошибка достижима и на сколько ходов тянется скрытая ветка после неё.
-- Для сравнения — то же для спуска головой вперёд (правильный).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local vis = def.visibleLoss or function() return false end
-- «ноги вперёд»: при спуске первой в шахту вошла пятка. Узнаём по первому состоянию «целиком ниже коридора»
-- на каждом ребре «было в коридоре → стало целиком ниже»: какая из крайних клеток ниже.
-- карман станции (две открытые клетки под коридором с дном) в «спуск» не входит
local pocketCell = {}
for x = 2, lvl.W - 1 do
  local c2, c3, c4, c5 = R.idx(lvl, x, 2), R.idx(lvl, x, 3), R.idx(lvl, x, 4), R.idx(lvl, x, 5)
  if lvl.cell[c2] == 0 and lvl.cell[c3] == 0 and lvl.cell[c4] == 0 and lvl.cell[c5] == 1 then pocketCell[c3] = true; pocketCell[c4] = true end
end
local function below(st)
  for _, c in ipairs(st.body) do local _, y = R.xy(lvl, c); if y <= 2 or pocketCell[c] then return false end end
  return true
end
local entryHeel, entryHead = {}, {}
local minDepth = { heel = nil, head = nil }
for i = 1, G.n do
  if G.flag[i] ~= 2 then
    local st = R.decode(lvl, G.keys[i])
    if not below(st) then
      for e = G.eStart.p[i - 1], G.eStart.p[i] - 1 do
        local j = G.edges.p[e]
        if G.flag[j] ~= 2 then
          local s2 = R.decode(lvl, G.keys[j])
          if below(s2) then
            local b = s2.body
            local _, yh = R.xy(lvl, b[#b]); local _, yf = R.xy(lvl, b[1])
            if yf > yh then entryHeel[j] = true; if not minDepth.heel or G.depth[j] < minDepth.heel then minDepth.heel = G.depth[j] end
            else entryHead[j] = true; if not minDepth.head or G.depth[j] < minDepth.head then minDepth.head = G.depth[j] end end
          end
        end
      end
    end
  end
end
-- замыкание вперёд от входов (все состояния, куда можно попасть после ошибки)
local function closure(seeds)
  local seen, q = {}, {}
  for i in pairs(seeds) do seen[i] = true; q[#q + 1] = i end
  local h = 1
  while h <= #q do
    local u = q[h]; h = h + 1
    for e = G.eStart.p[u - 1], G.eStart.p[u] - 1 do
      local v = G.edges.p[e]
      if not seen[v] and G.flag[v] ~= 2 then seen[v] = true; q[#q + 1] = v end
    end
  end
  return seen
end
local function report(name, seeds, md)
  local all = closure(seeds)
  local n, live, visN, hid = 0, 0, 0, 0
  for i in pairs(all) do
    n = n + 1
    if good[i] == 1 then live = live + 1 elseif vis(lvl, R.decode(lvl, G.keys[i])) then visN = visN + 1 else hid = hid + 1 end
  end
  local ne = 0
  for _ in pairs(seeds) do ne = ne + 1 end
  -- глубина: самое длинное кратчайшее расстояние от входа внутри области
  local maxd = 0
  for s in pairs(seeds) do
    local d, q, h = { [s] = 0 }, { s }, 1
    while h <= #q do
      local u = q[h]; h = h + 1
      for e = G.eStart.p[u - 1], G.eStart.p[u] - 1 do
        local v = G.edges.p[e]
        if all[v] and d[v] == nil then d[v] = d[u] + 1; if d[v] > maxd then maxd = d[v] end; q[#q + 1] = v end
      end
    end
  end
  print(string.format("%s: входов %d (самый ранний — после хода %s), дальше состояний %d: живых %d, видимых %d, скрытых %d; ветка тянется %d ходов",
    name, ne, tostring(md), n, live, visN, hid, maxd))
end
report("ошибка подсказки №1 (в шахту ногами вперёд)", entryHeel, minDepth.heel)
report("для сравнения: в шахту головой вперёд", entryHead, minDepth.head)
