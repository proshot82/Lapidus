-- build/l3v3/doors.lua [файл] — двери (живое → скрытое) по шагам ВСЕХ кратчайших путей и по всем живым состояниям:
-- класс (переход конфигурации мыла), ошибка плана (ход двигает мыло) или исполнения (мыло не трогали),
-- стойкость: минимум ходов до видимого (любое блуждание) и по «естественному продолжению» — ходы до ближайшего
-- события с мылом (все ли они вскрывают), глубина и размер области.
local L = dofile("build/l3v3/lib.lua")
local path = arg[1] or "levels/03.lua"
local ctx = L.load(path, 4)
local G = ctx.G
local on, opt = L.onShortest(ctx)
local paths = L.allShortest(ctx)
print(string.format("ходов %d, кратчайших путей %d, состояний на них %d", opt, #paths, (function() local c = 0 for _ in pairs(on) do c = c + 1 end return c end)()))
local function soapOnly(st) return L.cfg(ctx, st, true) end
local function isHid(j) return L.status(ctx, j) == "hid" end
-- анализ одной двери i→j
local function door(i, j)
  local si, sj = ctx.sts[i], ctx.sts[j]
  local plan = soapOnly(si) ~= soapOnly(sj)
  -- BFS по скрытой области от j
  local d, q, h, maxd = { [j] = 0 }, { j }, 1, 0
  local minVis, minEvent, eventVis, eventHid = 99, 99, 0, 0
  while h <= #q do
    local u = q[h]; h = h + 1
    local su = ctx.sts[u]
    for _, v in ipairs(L.edges(ctx, u)) do
      local sv = L.status(ctx, v)
      if sv == "vis" and d[u] + 1 < minVis then minVis = d[u] + 1 end
      if G.flag[v] ~= 2 and soapOnly(ctx.sts[v]) ~= soapOnly(su) then
        -- событие с мылом из скрытого состояния
        if d[u] + 1 <= minEvent then minEvent = d[u] + 1 end
        if sv == "vis" then eventVis = eventVis + 1 elseif sv == "hid" then eventHid = eventHid + 1 end
      end
      if sv == "hid" and d[v] == nil then d[v] = d[u] + 1; if d[v] > maxd then maxd = d[v] end; q[#q + 1] = v end
    end
  end
  return { plan = plan, minVis = minVis, minEvent = minEvent, eventVis = eventVis, eventHid = eventHid, deep = maxd, size = #q,
    cls = L.cfg(ctx, si) .. " → " .. L.cfg(ctx, sj) }
end
-- 1) по шагам всех кратчайших путей
print("\nДВЕРИ С КРАТЧАЙШИХ ПУТЕЙ (по состояниям на любом кратчайшем пути):")
local byStep = {}
for i in pairs(on) do
  if G.flag[i] == 0 then
    for _, j in ipairs(L.edges(ctx, i)) do
      if isHid(j) then
        local D = door(i, j)
        local k = G.depth[i]
        byStep[k] = byStep[k] or {}
        table.insert(byStep[k], D)
      end
    end
  end
end
local steps = {}
for k in pairs(byStep) do steps[#steps + 1] = k end
table.sort(steps)
if #steps == 0 then print("   нет") end
for _, k in ipairs(steps) do
  for _, D in ipairs(byStep[k]) do
    print(string.format("   шаг %2d (%s половина): %s | %s | до видимого мин. %d ходов; ближайшее событие с мылом через %d ходов (вскрывает: %d рёбер, остаётся скрытым: %d) | глубина %d, область %d",
      k, k < opt / 2 and "1-я" or "2-я", D.cls, D.plan and "ОШИБКА ПЛАНА (ход двигает мыло)" or "ошибка исполнения (мыло не трогали)",
      D.minVis, D.minEvent, D.eventVis, D.eventHid, D.deep, D.size))
  end
end
-- 2) по всем живым состояниям: классы дверей, из какой фазы (конфигурация живого состояния)
print("\nДВЕРИ ИЗ ВСЕХ ЖИВЫХ (класс перехода → число рёбер, число живых источников, мин/макс глубина источника):")
local agg, srcs = {}, {}
for i = 1, G.n do
  if G.flag[i] == 0 and ctx.good[i] == 1 then
    for _, j in ipairs(L.edges(ctx, i)) do
      if isHid(j) then
        local D = door(i, j)
        local a = agg[D.cls] or { n = 0, src = {}, dmin = 99, dmax = 0, plan = D.plan, minVis = 99, maxVis = 0 }
        agg[D.cls] = a
        a.n = a.n + 1; a.src[i] = true; a.dmin = math.min(a.dmin, G.depth[i]); a.dmax = math.max(a.dmax, G.depth[i])
        a.minVis = math.min(a.minVis, D.minVis); a.maxVis = math.max(a.maxVis, D.minVis)
        srcs[i] = true
      end
    end
  end
end
for k, a in pairs(agg) do
  local ns = 0 for _ in pairs(a.src) do ns = ns + 1 end
  print(string.format("   %s: рёбер %d из %d живых (глубина источников %d–%d), %s, вскрытие %d–%d ходов", k, a.n, ns, a.dmin, a.dmax, a.plan and "план" or "исполнение", a.minVis, a.maxVis))
end
-- 3) живые состояния второй половины: есть ли хоть одна дверь из состояния с глубиной ≥ opt/2 или из фазы после выбивания
local late, lateDoors = 0, 0
for i = 1, G.n do
  if G.flag[i] == 0 and ctx.good[i] == 1 and ctx.sts[i].pos[4] == 0 then
    late = late + 1
    for _, j in ipairs(L.edges(ctx, i)) do if isHid(j) then lateDoors = lateDoors + 1 end end
  end
end
print(string.format("\nживых состояний после выбивания подставки (деталь 4 смыта): %d; дверей в скрытое из них: %d", late, lateDoors))
-- 4) ходы из живых в видимое по фазам (для сравнения: где ошибки видимы)
local visByPhase = {}
for i = 1, G.n do
  if G.flag[i] == 0 and ctx.good[i] == 1 then
    local ph = L.cfg(ctx, ctx.sts[i])
    for _, j in ipairs(L.edges(ctx, i)) do
      local s = L.status(ctx, j)
      if s == "vis" or s == "wash" then
        local a = visByPhase[ph] or { vis = 0, wash = 0, states = {} }
        visByPhase[ph] = a
        if s == "vis" then a.vis = a.vis + 1 else a.wash = a.wash + 1 end
        a.states[i] = true
      end
    end
  end
end
print("\nходы живое → ВИДИМОЕ / смыт Лапидус по фазе (конфигурация живого состояния):")
for k, a in pairs(visByPhase) do
  local ns = 0 for _ in pairs(a.states) do ns = ns + 1 end
  print(string.format("   %-32s в видимое %4d, смыт %4d (из %d живых)", k, a.vis, a.wash, ns))
end
L.free(ctx)
