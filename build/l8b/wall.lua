-- build/l8b/wall.lua файл.lua — замуровка: каждую пустую клетку (без деталей и Лапидуса) по одной — стеной; решаемость, ходов,
-- скрытых %, абляция «брандспойт не бьёт». Класс: НЕСУЩАЯ (решение или абляции меняются) / мёртвая. Без ходов.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local F = dofile("build/l8a/filt.lua")
local path = arg[1]
local base = dofile(path)
local function metrics(def)
  local ok, lvl = pcall(R.compile, def)
  if not ok or #R.validate(lvl) > 0 then return { err = true } end
  local G = SV.explore(lvl, 1500000)
  if not G or not G.firstWin then local n = G and G.n or -1; if G then SV.freeGraph(G) end; return { solvable = false, n = n } end
  local good = SV.goodSet(G)
  local VL = V.compute(lvl, G, def, good)
  local m = V.measure(G, good, VL.newbie)
  local nwin = 0
  for i = 1, G.n do if G.flag[i] == 1 then nwin = nwin + 1 end end
  local r = { solvable = true, opt = m.opt, n = G.n, hid = m.hiddenPct, nwin = nwin }
  SV.freeGraph(G); require("ffi").C.free(good)
  local G2 = SV.explore(R.compile(def), 1500000, F.noHose)
  r.hose = G2 and (G2.firstWin and "РЕШАЕМ" or "нерешаем") or "CAP"
  if G2 then SV.freeGraph(G2) end
  return r
end
local function fmt(r)
  if r.err then return "невалиден" end
  if not r.solvable then return "НЕРЕШАЕМ n=" .. r.n end
  return string.format("ходов %d n=%d win=%d скр %.1f%% | без брандспойта: %s", r.opt, r.n, r.nwin, r.hid, r.hose)
end
local b = metrics(base)
print("база: " .. fmt(b))
local occ = {}
for _, o in ipairs(base.objects) do
  if o.at then occ[o.at[1] .. "," .. o.at[2]] = true end
  if o.cells then for _, c in ipairs(o.cells) do occ[c[1] .. "," .. c[2]] = true end end
end
local dead = {}
for y = 1, #base.grid do
  for x = 1, #base.grid[y] do
    if base.grid[y]:sub(x, x) == "." and not occ[x .. "," .. y] then
      local d = SV.deepcopy(base)
      d.grid[y] = d.grid[y]:sub(1, x - 1) .. "#" .. d.grid[y]:sub(x + 1)
      local r = metrics(d)
      local cls = (not r.solvable or r.err or r.opt ~= b.opt or r.nwin ~= b.nwin or r.hose ~= b.hose) and "НЕСУЩАЯ" or "мёртвая"
      if cls == "мёртвая" then dead[#dead + 1] = string.format("(%d,%d)", x, y) end
      print(string.format("(%2d,%d) %-8s %s", x, y, cls, fmt(r)))
      io.stdout:flush()
    end
  end
end
print("мёртвые: " .. (#dead > 0 and table.concat(dead, " ") or "нет"))
