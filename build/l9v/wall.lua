-- build/l9v/wall.lua файл.lua x,y [x,y ...] — замуровка клеток по одной: решение (та же длина? проходит ли исходное
-- кратчайшее решение), скрытых по линейке и по линейке+W+T+S, двери у пути, абляции. Результат — построчно в stdout
-- (запускать с перенаправлением в файл). Решение не печатается.
local L = dofile("build/l9v/lib.lua")
local R, V, SV = L.R, L.V, L.SV
local path = arg[1]
local base = dofile(path)
-- исходное кратчайшее решение (в памяти, не печатается)
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
local function extraRules(lvl)
  local W = lvl.W
  local function idx(x, y) return (y - 1) * W + x end
  local tags = {}
  for q, p in ipairs(lvl.pieces) do if p.tag then tags[p.tag] = q end end
  local function occ(s) local t = {} for q = 1, #s.pos do if s.pos[q] ~= 0 then t[s.pos[q]] = q end end return t end
  return function(s)
    local o = occ(s)
    for q, p in ipairs(lvl.pieces) do if p.movable and s.pos[q] ~= 0 and s.fixed[q] then
      for d = 1, 4 do if p.ports[d] then
        local t = lvl.nb[s.pos[q]][d]
        if t == 0 or lvl.cell[t] == R.WALL then return true end
        local r = o[t]
        if r and s.fixed[r] and not R.match(p.ports[d], lvl.pieces[r].ports[R.OPP[d]]) then return true end
      end end end end
    local q9 = o[idx(9, 7)]
    if q9 and s.fixed[q9] and lvl.pieces[q9].ports[R.RIGHT] ~= "V" then return true end
    local bodyMinX = 99
    for _, c in ipairs(s.body) do local x, y = R.xy(lvl, c)
      if (y == 5 and x <= 5) or (x == 2 and (y == 6 or y == 7)) or y == 8 then bodyMinX = math.min(bodyMinX, (y == 5) and x or 0) end end
    for _, tg in ipairs({ "tee", "plug" }) do local q = tags[tg]
      if q and s.pos[q] ~= 0 and not s.fixed[q] then
        local x, y = R.xy(lvl, s.pos[q])
        local stacked = (x == 6 and y == 4 and o[idx(6, 5)] and not s.fixed[o[idx(6, 5)]])
        if ((y == 5 and x <= 6) or stacked) and not (bodyMinX < (stacked and 6 or x)) then return true end
      end end
    return false
  end
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
  local ex = extraRules(lvl)
  local arr = {}
  for i = 1, G.n do if G.flag[i] ~= 2 then arr[i] = VL.newbie[i] or (good[i] ~= 1 and ex(R.decode(lvl, G.keys[i]))) end end
  local b = V.measure(G, good, arr)
  local nwin = 0
  for i = 1, G.n do if G.flag[i] == 1 then nwin = nwin + 1 end end
  local same = replay(def, sol)
  local opt = G.depth[G.firstWin]
  SV.freeGraph(G); require("ffi").C.free(good)
  local abl = ""
  if opt == #sol then
    local r = SV.ablations(def, { cap = 3000000 })
    local s = {}
    for _, x in ipairs(r) do if x.solvable ~= false then s[#s+1] = x.name end end
    abl = (#s == 0) and "абляции все нерешаемы" or ("абляции РЕШАЕМЫ: " .. table.concat(s, ","))
  end
  print(string.format("%s: ходов %d (база %d), исходное решение %s, выигрышных %d, n=%d | скрытых %.1f %% (у пути [%s]) | +W+T+S %.1f %% (у пути [%s]) | %s",
    label, opt, #sol, same and "проходит" or "НЕ проходит", nwin, a.live + a.vis + a.hid, a.hiddenPct, a.deepList, b.hiddenPct, b.deepList, abl))
  io.stdout:flush()
end
for k = 2, #arg do
  local x, y = arg[k]:match("^(%d+),(%d+)$")
  x, y = tonumber(x), tonumber(y)
  local d = dofile(path)
  if arg[k] == "base" then run(d, "база")
  else
    assert(d.grid[y]:sub(x, x) == ".", "не пусто " .. arg[k])
    d.grid[y] = d.grid[y]:sub(1, x - 1) .. "#" .. d.grid[y]:sub(x + 1)
    run(d, "(" .. x .. "," .. y .. ")")
  end
end
