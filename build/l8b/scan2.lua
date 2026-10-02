-- build/l8b/scan2.lua R Lmax yq "xx list" — разведка семейства Б2 («два выстрела и перехват» с переходником):
-- кран Q (вправо V) в левой стене на высоте yq, шахта столбец 3 от полки (ряд 3); кран X (влево V) на тумбе в столбце xx
-- на высоте yx, шахта столбец xx-1; полка ряд 3 от столбца 3 до xx-1 с дырами H (1–2) для тела; детали: пробка q (влево N)
-- и ниппель n (N,N) на полке; ванна (вверх V) на полу. Печатает строку на раскладку (без ходов).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local F = dofile("build/l8a/filt.lua")
local RR, LMAX, YQ = tonumber(arg[1] or 3), tonumber(arg[2] or 6), tonumber(arg[3] or 5)
local XXS = {}
for h in (arg[4] or "11"):gmatch("%d+") do XXS[#XXS + 1] = tonumber(h) end
local mk = dofile("build/l8b/fam2.lua")(RR, LMAX, YQ)
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
for _, xx in ipairs(XXS) do
  local inner = {}
  for x = 4, xx - 2 do inner[#inner + 1] = x end
  local holeSets = {}
  for i = 1, #inner do for j = i + 1, #inner do holeSets[#holeSets + 1] = { inner[i], inner[j] } end end
  for _, yx in ipairs({ 5, 6 }) do
    for _, holes in ipairs(holeSets) do
      local isHole = {}
      for _, h in ipairs(holes) do isHole[h] = true end
      local solid = {}
      for _, x in ipairs(inner) do if not isHole[x] then solid[#solid + 1] = x end end
      for _, pq in ipairs(solid) do for _, pn in ipairs(solid) do
        if pq < holes[1] and pn > holes[1] then
          for _, xf in ipairs({ math.floor((3 + xx - 1) / 2) }) do
            local sx = (xf <= 4) and 6 or 3
            local r = eval(mk(xx, yx, holes, pq, pn, xf, sx))
            print(string.format("R=%d L=%d yq=%d X=(%d,%d) дыры %s q=%d n=%d ванна=%d: %s", RR, LMAX, YQ, xx, yx, table.concat(holes, ","), pq, pn, xf, r))
            io.stdout:flush()
          end
        end
      end end
    end
  end
end
