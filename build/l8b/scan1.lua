-- build/l8b/scan1.lua [R] [Lmax] [body-hole-list] — разведка семейства Ш2: полка в ряду 3 над комнатой, кран A слева на тумбе
-- (вправо V, шахта столбец 5), кран B справа в стене (влево V, шахта столбец 12), потолочный кран D (вниз V) над полкой,
-- детали n (ниппель), u (пробка Н вверх), b (пробка Н вправо) на полке; дыра в полке для тела — параметр.
-- Печатает по строке на раскладку: решаем/ходов, без брандспойта, скрытых %, двери по половинам, обезьяна. Ходов не печатает.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local F = dofile("build/l8a/filt.lua")
local RR, LMAX = tonumber(arg[1] or 2), tonumber(arg[2] or 6)
local bodyHoles = {}
for h in (arg[3] or "8"):gmatch("%d+") do bodyHoles[#bodyHoles + 1] = tonumber(h) end
local function mk(xd, holes, parts, xf)
  local rows = {
    "################",
    "################",
    "####........####",
    "################",
    "###S........Y###",
    "####........####",
    "####........####",
    "####........####",
    "####........####",
    "################",
  }
  local function set(x, y, ch) rows[y] = rows[y]:sub(1, x - 1) .. ch .. rows[y]:sub(x + 1) end
  for _, h in ipairs(holes) do set(h, 4, ".") end
  set(xd, 2, ".")
  set(4, 5, "."); set(13, 5, ".")
  local objs = {
    { kind = "source", at = { xd, 2 }, ports = { down = "V" } },
    { kind = "source", at = { 4, 5 }, ports = { right = "V" } },
    { kind = "source", at = { 13, 5 }, ports = { left = "V" } },
    { kind = "fixture", what = "bath", at = { xf, 9 }, ports = { up = "V" } },
  }
  local P = {
    n = { kind = "fitting", what = "nipple", tag = "nip", ports = { left = "N", right = "N" } },
    u = { kind = "fitting", what = "plug", tag = "plug", ports = { up = "N" } },
    b = { kind = "fitting", what = "plug", tag = "plug2", ports = { right = "N" } },
  }
  for k, x in pairs(parts) do local o = {}; for kk, vv in pairs(P[k]) do o[kk] = vv end; o.at = { x, 3 }; objs[#objs + 1] = o end
  local sx = (xf == 5) and 7 or 5
  objs[#objs + 1] = { kind = "lapidus", cells = { { sx, 9 }, { sx + 1, 9 } }, head = 2 }
  return { id = 8, flat = 8, name = "Брандспойт", length = { 2, LMAX }, pressure = RR, grid = rows, objects = objs,
    ablations = { { name = "брандспойт не бьёт", filter = F.noHose } } }
end
local function eval(def)
  local ok, lvl = pcall(R.compile, def)
  if not ok then return "ошибка " .. tostring(lvl) end
  local errs = R.validate(lvl)
  if #errs > 0 then return "невалиден: " .. errs[1] end
  local G = SV.explore(lvl, 1500000)
  if not G then return "CAP" end
  if not G.firstWin then local n = G.n; SV.freeGraph(G); return "нерешаем n=" .. n end
  local opt, n = G.depth[G.firstWin], G.n
  local good = SV.goodSet(G)
  local VL = V.compute(lvl, G, def, good)
  local m = V.measure(G, good, VL.newbie)
  local path = m.path
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
  local G2 = SV.explore(R.compile(def), 1500000, F.noHose)
  local hose = (G2 == nil) and "CAP" or (G2.firstWin and "РЕШАЕМ" or "нерешаем")
  if G2 then SV.freeGraph(G2) end
  return string.format("ходов %2d n=%6d win=%d скр %5.1f%% обез %.2f глуб %2d двери %d/%d | без брандспойта: %s", opt, n, nwin, m.hiddenPct, m.smart, m.maxDeep, h1, h2, hose)
end
local cols = { 6, 7, 8, 9, 10, 11 }
local orders = { { "n", "u", "b" }, { "n", "b", "u" }, { "u", "n", "b" }, { "u", "b", "n" }, { "b", "n", "u" }, { "b", "u", "n" } }
local cnt = 0
for _, bh in ipairs(bodyHoles) do
  local holes = { 5, 12, bh }
  for _, xd in ipairs(cols) do
    if xd ~= bh then
      local free = {}
      for _, c in ipairs(cols) do if c ~= bh and c ~= xd then free[#free + 1] = c end end
      -- три позиции из free (по возрастанию), шесть порядков деталей
      for i = 1, #free do for j = i + 1, #free do for k = j + 1, #free do
        for _, ord in ipairs(orders) do
          local parts = { [ord[1]] = free[i], [ord[2]] = free[j], [ord[3]] = free[k] }
          for _, xf in ipairs({ 7 }) do
            local r = eval(mk(xd, holes, parts, xf))
            cnt = cnt + 1
            print(string.format("R=%d L=%d дыра %d D=%d n=%d u=%d b=%d ванна=%d: %s", RR, LMAX, bh, xd, parts.n, parts.u, parts.b, xf, r))
            io.stdout:flush()
          end
        end
      end end end
    end
  end
end
