-- build/l3v3/walk.lua [файл] — прогулки и выбор по всем кратчайшим; подграф после установки ступеньки;
-- варианты верха (без смены ядра): можно ли укоротить хвост.
local L = dofile("build/l3v3/lib.lua")
local R = L.R
local path = arg[1] or "levels/03.lua"
local ctx = L.load(path, 4)
local G = ctx.G
local dist = L.distToWin(ctx)
local paths, opt = L.allShortest(ctx)
local function objs(i) local st = ctx.sts[i]; local t = {} for q = 1, #st.pos do t[#t + 1] = st.pos[q] end return table.concat(t, ",") end
print(string.format("кратчайших %d, ходов %d", #paths, opt))
local seen = {}
for pi, p in ipairs(paths) do
  local ev, streaks, streak, fwd, live = {}, {}, 0, {}, {}
  for k = 1, #p - 1 do
    if objs(p[k]) ~= objs(p[k + 1]) then ev[#ev + 1] = k; if streak > 0 then streaks[#streaks + 1] = streak end; streak = 0 else streak = streak + 1 end
    local f, l = 0, 0
    for _, j in ipairs(L.edges(ctx, p[k])) do
      if G.flag[j] ~= 2 and ctx.good[j] == 1 then l = l + 1; if dist[j] and dist[j] < dist[p[k]] then f = f + 1 end end
    end
    fwd[#fwd + 1] = f; live[#live + 1] = l
  end
  if streak > 0 then streaks[#streaks + 1] = streak end
  local key = table.concat(ev, ",") .. "|" .. table.concat(streaks, ",")
  if not seen[key] then
    seen[key] = true
    print(string.format("путь %d: события на ходах %s; прогулки %s; ходов «вперёд» по шагам %s; живых продолжений %s", pi, table.concat(ev, ","), table.concat(streaks, ","), table.concat(fwd, ""), table.concat(live, "")))
  end
end
-- самая длинная серия шагов с единственным ходом вперёд
do
  local p = paths[1]
  local run, maxRun, at = 0, 0, 0
  for k = 1, #p - 1 do
    local f = 0
    for _, j in ipairs(L.edges(ctx, p[k])) do if G.flag[j] ~= 2 and ctx.good[j] == 1 and dist[j] and dist[j] < dist[p[k]] then f = f + 1 end end
    if f == 1 then run = run + 1; if run > maxRun then maxRun = run; at = k end else run = 0 end
  end
  print(string.format("самая длинная серия шагов с единственным ходом вперёд: %d (кончается на ходу %d)", maxRun, at))
end
-- подграф после установки ступеньки: живые состояния с мылом на ступеньке
local step = ctx.step
local n, hist = 0, {}
for i = 1, G.n do
  if G.flag[i] == 0 and ctx.good[i] == 1 and ctx.sts[i].pos[3] == step then n = n + 1; hist[dist[i]] = (hist[dist[i]] or 0) + 1 end
end
local parts = {}
for d = 0, 60 do if hist[d] then parts[#parts + 1] = d .. ":" .. hist[d] end end
print(string.format("живых с мылом на ступеньке: %d; до победы (ходов:состояний) %s", n, table.concat(parts, " ")))
-- ходы в проигрыш из состояний с мылом на ступеньке
local lose = 0
for i = 1, G.n do
  if G.flag[i] == 0 and ctx.good[i] == 1 and ctx.sts[i].pos[3] == step then
    for _, j in ipairs(L.edges(ctx, i)) do if L.status(ctx, j) ~= "live" and L.status(ctx, j) ~= "win" then lose = lose + 1 end end
  end
end
print(string.format("ходов в проигрыш/смыв из состояний с мылом на ступеньке: %d", lose))
L.free(ctx)
-- варианты верха
local base = dofile(path)
local function variant(name, grid, objs2)
  local d = L.SV.deepcopy(base); d.ablations = base.ablations
  d.grid = grid
  d.objects = objs2
  local r = L.metrics(d)
  local abl = ""
  if r.solvable then
    local a = L.SV.ablations(d, { cap = 3000000 }); local s = {}
    for _, e in ipairs(a) do if e.solvable ~= false then s[#s + 1] = e.name end end
    abl = #s > 0 and (" | абл. РЕШАЕМЫ: " .. table.concat(s, ", ")) or " | абл. нерешаемы"
  end
  print(string.format("%-60s %s%s", name, L.fmt(r), abl))
end
local soaps = { { at = { 4, 4 }, kind = "porcelain", tag = "soap" }, { at = { 5, 7 }, kind = "porcelain", tag = "soap" },
  { cells = { { 4, 7 }, { 4, 6 }, { 3, 6 }, { 2, 6 } }, head = 4, kind = "lapidus" } }
local function withPorts(a, b) local t = { a, b } for _, s in ipairs(soaps) do t[#t + 1] = s end return t end
print("\nВАРИАНТЫ ВЕРХА (ядро то же):")
variant("В1 стояк (9,2) порт left=V, колонка x=10 замурована", {
  "###########", "#####....##", "######.####", "##...#.####", "##.#.#.####", "#......####", "###....####", "#####~#####" },
  withPorts({ at = { 9, 2 }, kind = "source", ports = { left = "V" } }, { at = { 6, 2 }, kind = "fixture", ports = { right = "N" }, what = "sink" }))
variant("В2 стояк (9,4) порт up=V, спуск (9,3), x=10 замурована", {
  "###########", "#####....##", "######.#.##", "##...#.#.##", "##.#.#.####", "#......####", "###....####", "#####~#####" },
  withPorts({ at = { 9, 4 }, kind = "source", ports = { up = "V" } }, { at = { 6, 2 }, kind = "fixture", ports = { right = "N" }, what = "sink" }))
variant("В3 стояк (8,4) порт up=V, спуск (8,3) сразу за шахтой", {
  "###########", "#####...###", "######..###", "##...#..###", "##.#.#.####", "#......####", "###....####", "#####~#####" },
  withPorts({ at = { 8, 4 }, kind = "source", ports = { up = "V" } }, { at = { 6, 2 }, kind = "fixture", ports = { right = "N" }, what = "sink" }))
variant("В4 как есть, но стояк (10,3) порт left=V (без спуска)", {
  "###########", "#####.....#", "######.##.#", "##...#.####", "##.#.#.####", "#......####", "###....####", "#####~#####" },
  withPorts({ at = { 10, 3 }, kind = "source", ports = { up = "V" } }, { at = { 6, 2 }, kind = "fixture", ports = { right = "N" }, what = "sink" }))
