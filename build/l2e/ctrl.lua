-- build/l2e/ctrl.lua файл.lua — контроли (обязаны остаться решаемы) и дополнительные абляции кандидата кв. 2. Только метрики.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local EV = dofile("build/l2e/ev.lua")
local file = arg[1]
local function load() return dofile(file) end
local function run(def, filter, label)
  local ok, lvl = pcall(R.compile, def); if not ok then print(label .. ": не компилируется"); return end
  local e = R.validate(lvl); if #e > 0 then print(label .. ": невалиден"); return end
  if filter then
    local G = SV.explore(lvl, 3000000, filter)
    print(string.format("%s: %s", label, G.firstWin and ("решаем за " .. G.depth[G.firstWin] .. ", сост. " .. G.n) or ("НЕРЕШАЕМ (" .. G.n .. ")")))
    SV.freeGraph(G)
  else
    local r = EV.eval(def, nil, true, true)
    if r.fail then print(string.format("%s: %s", label, r.fail == "unsolvable" and ("НЕРЕШАЕМ (" .. r.n .. ")") or r.fail)) else
      print(string.format("%s: решаем за %d, сост. %d, скрытых %.0f %% (перевёрн. %.0f %%), глубина %d, обезьяна %.2f %%, конф %d",
        label, r.opt, r.n, r.pctAuthor, r.pctFlip, r.deep, r.smart, r.nwcfg)) end
  end
end
local function wall(d, tag)
  local keep = {}
  for _, o in ipairs(d.objects) do
    if o.tag == tag then local r = d.grid[o.at[2]]; d.grid[o.at[2]] = r:sub(1, o.at[1] - 1) .. "#" .. r:sub(o.at[1] + 1)
    else keep[#keep + 1] = o end
  end
  d.objects = keep
end
local function flipAll(d)
  for _, o in ipairs(d.objects) do if o.kind == "stub" then for s, t in pairs(o.ports) do o.ports[s] = t == "N" and "V" or "N" end end end
end
run(load(), nil, "база")
do local d = load(); wall(d, "low"); wall(d, "under"); run(d, nil, "контроль: нижние крючья (low, under) замурованы") end
do local d = load(); wall(d, "low"); run(d, nil, "контроль: крюк low замурован") end
do local d = load(); wall(d, "under"); run(d, nil, "контроль: крюк under замурован") end
do local d = load(); wall(d, "top"); run(d, nil, "абляция: крюк дымохода замурован") end
do local d = load(); wall(d, "row"); run(d, nil, "абляция: крюк ряда коридора замурован") end
do local d = load(); flipAll(d); run(d, nil, "контроль/абляция: все резьбы наоборот") end
do local d = load(); for _, o in ipairs(d.objects) do if o.tag == "low" or o.tag == "under" then for s, t in pairs(o.ports) do o.ports[s] = t == "N" and "V" or "N" end end end; run(d, nil, "контроль: нижние крючья наоборот") end
for _, L in ipairs({ { 2, 3 }, { 3, 4 }, { 2, 5 } }) do local d = load(); d.length = L; run(d, nil, string.format("длина %d–%d", L[1], L[2])) end
do local d = load(); local he = d.hintError; run(d, function(lvl, st, ns) return not he(lvl, st, ns) end, "контроль: ошибка подсказки (захват крюка под коридором) запрещена") end
-- по одной пустой клетке: замуровать
local base = load()
local same, change, unsol = {}, {}, {}
local r0 = EV.eval(base, nil, true, true)
local b0 = string.format("%d %.0f %d", r0.opt, r0.pctAuthor, r0.deep)
for y = 1, #base.grid do for x = 1, #base.grid[1] do
  if base.grid[y]:sub(x, x) == "." then
    local d = load(); local occ = false
    for _, o in ipairs(d.objects) do
      if o.at and o.at[1] == x and o.at[2] == y then occ = true end
      if o.cells then for _, c in ipairs(o.cells) do if c[1] == x and c[2] == y then occ = true end end end
    end
    if not occ then
      d.grid[y] = d.grid[y]:sub(1, x - 1) .. "#" .. d.grid[y]:sub(x + 1)
      local r = EV.eval(d, nil, true, true)
      local tag = string.format("(%d,%d)", x, y)
      if r.fail then unsol[#unsol + 1] = tag
      else local b = string.format("%d %.0f %d", r.opt, r.pctAuthor, r.deep); if b == b0 then same[#same + 1] = tag else change[#change + 1] = tag .. "→" .. b end end
    end
  end
end end
print("клетка → нерешаем/невалиден: " .. #unsol .. "  " .. table.concat(unsol, " "))
print("клетка → ничего не меняет (ходы, скрытые, глубина): " .. #same .. "  " .. table.concat(same, " "))
print("клетка → меняет метрики: " .. #change .. "  " .. table.concat(change, " "))
