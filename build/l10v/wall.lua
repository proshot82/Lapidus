-- build/l10v/wall.lua файл.lua x,y [x,y ...] — замуровка клеток по одной (o34; по образцу build/l9v2/wall.lua): решаем ли, длина,
-- проходит ли исходное кратчайшее решение, скрытых по разметке файла и файл+Y (Y — тройник закрыл колодец, мойка сухая),
-- той же длиной (кандидат в мёртвое). Решение не печатается.
local L = dofile("build/l10v/lib.lua")
local R, V, SV = L.R, L.V, L.SV
local path = arg[1]
local base = dofile(path)
local function solution(def)
  local lvl = R.compile(def)
  local G = SV.explore(lvl, 3000000)
  local mv, x = {}, G.firstWin
  while x ~= 1 do table.insert(mv, 1, G.pmove[x]); x = G.parent[x] end
  SV.freeGraph(G)
  return mv
end
local sol = solution(base)
local function replay(def, mv)
  local lvl = R.compile(def)
  local st = R.newState(lvl)
  for _, m in ipairs(mv) do
    local mm = R.MOVES[m]
    st = R.move(lvl, st, mm.which, mm.dir)
    if not st then return false end
  end
  return R.isWin(lvl, st)
end
local function run(def, label)
  local lvl = R.compile(def)
  local errs = R.validate(lvl)
  if #errs > 0 then print(label .. ": ОШИБКИ " .. table.concat(errs, ";")); io.stdout:flush(); return end
  local G = SV.explore(lvl, 3000000)
  if not G.firstWin then print(string.format("%s: НЕРЕШАЕМ (n=%d) → несущая", label, G.n)); SV.freeGraph(G); io.stdout:flush(); return end
  local good = SV.goodSet(G)
  local VL = V.compute(lvl, G, def, good)
  local a = V.measure(G, good, VL.newbie)
  local tee, sinkQ
  for q, p in ipairs(lvl.pieces) do if p.tag == "tee" then tee = q end; if p.what == "sink" then sinkQ = q end end
  local srcC = R.idx(lvl, 6, 7)
  local arr = {}
  for i = 1, G.n do if G.flag[i] ~= 2 then
    local v = VL.newbie[i]
    if not v and good[i] ~= 1 then local s = R.decode(lvl, G.keys[i]); v = s.pos[tee] == srcC and s.fixed[tee] and not R.water(lvl, s).wet[sinkQ] end
    arr[i] = v end end
  local b = V.measure(G, good, arr)
  local same = replay(def, sol)
  local opt = G.depth[G.firstWin]
  SV.freeGraph(G); require("ffi").C.free(good)
  local abl = ""
  if same and opt == #sol then
    local r = SV.ablations(def, { cap = 3000000 })
    local s = {}
    for _, x in ipairs(r) do if x.solvable ~= false then s[#s+1] = x.name end end
    abl = (#s == 0) and "абляции все нерешаемы" or ("абляции РЕШАЕМЫ: " .. table.concat(s, ","))
  end
  print(string.format("%s: ходов %d (база %d), исходное решение %s | скрытых %.1f %% (у пути [%s]) | файл+Y %.1f %% | %s",
    label, opt, #sol, same and "проходит" or "НЕ проходит", a.hiddenPct, a.deepList, b.hiddenPct, abl))
  io.stdout:flush()
end
for k = 2, #arg do
  local d = dofile(path)
  if arg[k] == "base" then run(d, "база") else
    local x, y = arg[k]:match("^(%d+),(%d+)$"); x, y = tonumber(x), tonumber(y)
    assert(d.grid[y]:sub(x, x) == ".", "не пусто " .. arg[k])
    d.grid[y] = d.grid[y]:sub(1, x - 1) .. "#" .. d.grid[y]:sub(x + 1)
    run(d, "(" .. x .. "," .. y .. ")")
  end
end
