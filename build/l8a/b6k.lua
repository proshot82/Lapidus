-- build/l8a/b6k.lua — кв. 8, доводка b6 (01.10): дешёвые кандидаты на скрытую ошибку плана без смены ядра.
-- luajit build/l8a/b6k.lua — для каждой правки b6 печатает: ходы, состояния, живые / видимые / скрытые (общая линейка
-- tools/vislib.lua, мерка новичка), рёбра живое→скрытое, неустойчивые переходы, решаемые абляции. Решения не печатаются.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local base = dofile("build/l8a/c/b6.lua")

local function wall(d, cells)
  for _, c in ipairs(cells) do
    local x, y = c[1], c[2]
    assert(d.grid[y]:sub(x, x) == ".", "не пусто: " .. x .. "," .. y)
    d.grid[y] = d.grid[y]:sub(1, x - 1) .. "#" .. d.grid[y]:sub(x + 1)
  end
end
local function decoy(d, realAt, fakeAt)
  for _, o in ipairs(d.objects) do if o.tag == "plug" then o.at = realAt end end
  table.insert(d.objects, 2, { kind = "fitting", what = "plug", tag = "fake", at = fakeAt, ports = { left = "V" } })
end

local K = {
  { "k1 пол в шахте под Q: тело может спихнуть пробку с полочки", function(d) wall(d, { { 6, 5 } }) end },
  { "k2 то же + уступ в колодце: спихнутая пробка остаётся в ряду кранов", function(d) wall(d, { { 6, 5 }, { 8, 5 } }) end },
  { "k3 пробка-обманка (резьба В) рядом на полочке, настоящая у шахты", function(d) decoy(d, { 7, 2 }, { 8, 2 }) end },
  { "k4 пробка-обманка у шахты, настоящая за ней", function(d) decoy(d, { 8, 2 }, { 7, 2 }) end },
  { "k5 напор 3 вместо 2", function(d) d.pressure = 3 end },
}

for _, k in ipairs(K) do
  local d = SV.deepcopy(base)
  k[2](d)
  local lvl = R.compile(d)
  local G = SV.explore(lvl, 3000000)
  local line
  if not G.firstWin then
    line = string.format("НЕРЕШАЕМ (состояний %d)", G.n)
  else
    local good = SV.goodSet(G)
    local VL = V.compute(lvl, G, d, good)
    local live, vis, hid, doors, wins = 0, 0, 0, 0, 0
    local hidden = {}
    for i = 1, G.n do
      if G.flag[i] == 1 then wins = wins + 1 end
      if G.flag[i] ~= 2 then
        if good[i] == 1 then live = live + 1 elseif VL.newbie[i] then vis = vis + 1 else hid = hid + 1; hidden[i] = true end
      end
    end
    for i = 1, G.n do
      if good[i] == 1 then for e = G.eStart.p[i - 1], G.eStart.p[i] - 1 do if hidden[G.edges.p[e]] then doors = doors + 1 end end end
    end
    local ab = {}
    for _, a in ipairs(SV.ablations(d, { cap = 3000000 })) do if a.solvable ~= false then ab[#ab + 1] = a.name end end
    line = string.format("ходов %d | состояний %d (живых %d, видимых %d, скрытых %d) | выигрышных %d | рёбер живое→скрытое %d | неустойчивых %d | абляции решаемы: [%s]",
      G.depth[G.firstWin], G.n, live, vis, hid, wins, doors, G.unstable, table.concat(ab, ", "))
    require("ffi").C.free(good)
  end
  print(k[1] .. ": " .. line)
  SV.freeGraph(G)
end
