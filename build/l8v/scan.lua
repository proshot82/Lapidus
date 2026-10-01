-- build/l8v/scan.lua [вариант] — скептик кв. 8: разведка семейства «два крана + ниппель как якорь для головы».
-- Скелет b5 (левая стена, Q в ней, X справа, ванна внизу, старт слева внизу). Перебираются: резьба Q (N/V),
-- клетки пробки и ниппеля на полках (полка = стена под деталью), положение ванны. Для каждой раскладки — решаема ли,
-- ходов, скрытых % (мерка новичка), двери по половинам пути, абляция «брандспойт не бьёт». Ходы не печатаются.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local F = dofile("build/l8a/filt.lua")
local variant = arg[1] or "N"
local function mk(qth, plug, nip, bath, extra)
  local rows = {
    "#############",
    "#####.......#",
    "#####.......#",
    "####........#",
    "#####.......#",
    "#####.......#",
    "#####.......#",
    "#####.......#",
    "#############",
  }
  local function set(x, y, ch) rows[y] = rows[y]:sub(1, x - 1) .. ch .. rows[y]:sub(x + 1) end
  -- полки под деталями
  for _, c in ipairs({ plug, nip }) do if c[2] < 8 then set(c[1], c[2] + 1, "#") end end
  for _, c in ipairs(extra or {}) do set(c[1], c[2], "#") end
  local plugPorts = (qth == "N") and { left = "V" } or { left = "N" }
  local objs = {
    { kind = "fitting", what = "plug", tag = "plug", at = { plug[1], plug[2] }, ports = plugPorts },
    { kind = "fitting", what = "nipple", tag = "nip", at = { nip[1], nip[2] }, ports = { left = "N", right = "N" } },
    { kind = "source", at = { 5, 4 }, ports = { right = qth } },
    { kind = "source", at = { 11, 4 }, ports = { left = "V" } },
    { kind = "fixture", what = "bath", at = { bath[1], bath[2] }, ports = { up = "V" } },
    { kind = "lapidus", cells = { { 6, 8 }, { 7, 8 } }, head = 2 },
  }
  return {
    id = 8, flat = 8, name = "Брандспойт", length = { 2, 5 }, pressure = 2, grid = rows, objects = objs,
    ablations = { { name = "брандспойт не бьёт", filter = F.noHose } },
  }
end
local function eval(def)
  local ok, lvl = pcall(R.compile, def)
  if not ok then return "ошибка компиляции" end
  local errs = R.validate(lvl)
  if #errs > 0 then return "невалиден: " .. errs[1] end
  local G = SV.explore(lvl, 400000)
  if not G then return "CAP" end
  if not G.firstWin then local n = G.n; SV.freeGraph(G); return "нерешаем n=" .. n end
  local good = SV.goodSet(G)
  local VL = V.compute(lvl, G, def, good)
  local m = V.measure(G, good, VL.newbie)
  -- двери с кратчайшего пути по половинам
  local path, x = {}, G.firstWin
  while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
  table.insert(path, 1, 1)
  local ES, E = G.eStart.p, G.edges.p
  local h1, h2 = 0, 0
  for k = 1, #path - 1 do
    local s, c = path[k], 0
    for e = ES[s - 1], ES[s] - 1 do if m.hidden[E[e]] then c = c + 1 end end
    if c > 0 then if (k - 1) < (#path - 1) / 2 then h1 = h1 + 1 else h2 = h2 + 1 end end
  end
  local nwin = 0
  for i = 1, G.n do if G.flag[i] == 1 then nwin = nwin + 1 end end
  SV.freeGraph(G); require("ffi").C.free(good)
  local ab = SV.ablations(def, { cap = 400000 })
  return string.format("ходов %2d n=%6d win=%d скрытых %5.1f%% обез %.2f глуб %2d двери %d/%d | без брандспойта: %s",
    m.opt, G.n, nwin, m.hiddenPct, m.smart, m.maxDeep, h1, h2, ab[1].solvable == false and "нерешаем" or "РЕШАЕМ")
end
local shelves = {}
for y = 2, 3 do for x = 6, 10 do shelves[#shelves + 1] = { x, y } end end
local baths = { { 8, 8 }, { 9, 8 } }
local cnt = 0
for _, b in ipairs(baths) do
  for _, p in ipairs(shelves) do
    for _, n in ipairs(shelves) do
      if not (p[1] == n[1] and p[2] == n[2]) and not (p[1] == n[1] and math.abs(p[2] - n[2]) == 1) then
        local def = mk(variant, p, n, b)
        local r = eval(def)
        cnt = cnt + 1
        print(string.format("Q=%s пробка(%d,%d) ниппель(%d,%d) ванна(%d,%d): %s", variant, p[1], p[2], n[1], n[2], b[1], b[2], r))
        io.stdout:flush()
      end
    end
  end
end
