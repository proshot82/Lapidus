-- build/l9j/local.lua базовый.lua seed N — локальный перебор вокруг ручного кандидата: переключает 1–2 клетки поля
-- (кроме скелета: шахта, колонка, стояк, лаз, уступ тройника, ниша) и/или сдвигает старт Лапидуса.
-- Пишет строки с метриками в build/l9j/local_<seed>.txt.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local E = dofile("build/l9j/eval.lua")
local base, seed, N = arg[1], tonumber(arg[2] or 1), tonumber(arg[3] or 200)
math.randomseed(seed)
local def0 = dofile(base)
local H, W = #def0.grid, #def0.grid[1]
local PROT = {}
for _, o in ipairs(def0.objects) do
  if o.at then PROT[o.at[1] .. "," .. o.at[2]] = true end
end
for _, c in ipairs({ "6,3", "7,3", "7,4", "7,5", "7,6", "7,7", "5,7", "6,7", "5,8", "6,8", "6,6", "6,4" }) do PROT[c] = true end
local out = io.open("build/l9j/local_" .. seed .. ".txt", "w")
local function copy(t) local c = {} for k, v in pairs(t) do c[k] = type(v) == "table" and copy(v) or v end return c end
local seen = {}
for it = 1, N do
  local def = dofile(base)
  local g = {}
  for y = 1, H do g[y] = {} for x = 1, W do g[y][x] = def.grid[y]:sub(x, x) end end
  local k = math.random(1, 3)
  local changes = {}
  for _ = 1, k do
    local x, y = math.random(2, W - 1), math.random(3, H - 2)
    if not PROT[x .. "," .. y] then
      g[y][x] = (g[y][x] == "#") and "." or "#"
      changes[#changes + 1] = x .. "," .. y
    end
  end
  for y = 1, H do def.grid[y] = table.concat(g[y]) end
  -- иногда сдвигаем Лапидуса: случайный путь той же длины из случайной свободной клетки
  local lap
  for _, o in ipairs(def.objects) do if o.kind == "lapidus" then lap = o end end
  if math.random() < 0.5 then
    local L = #lap.cells
    for _ = 1, 100 do
      local x, y = math.random(2, W - 1), math.random(3, H - 2)
      local c, ok = {}, true
      local cx, cy = x, y
      for i = 1, L do
        if g[cy][cx] ~= "." or PROT[cx .. "," .. cy] and not (cx == 6 and cy == 3) then ok = false break end
        for _, o in ipairs(def.objects) do if o.at and o.at[1] == cx and o.at[2] == cy then ok = false end end
        for _, o in ipairs(c) do if o[1] == cx and o[2] == cy then ok = false end end
        if not ok then break end
        c[#c + 1] = { cx, cy }
        local d = math.random(4)
        cx, cy = cx + ({ 0, 1, 0, -1 })[d], cy + ({ -1, 0, 1, 0 })[d]
      end
      if ok then lap.cells = c; lap.head = (math.random() < 0.5) and 1 or L; break end
    end
  end
  local key = table.concat(def.grid, "|") .. "/" .. (function() local t = {} for _, c in ipairs(lap.cells) do t[#t+1] = c[1] .. "," .. c[2] end return table.concat(t, ";") end)() .. "/" .. lap.head
  if not seen[key] then
    seen[key] = true
    local ok, r = pcall(E.eval, def, 300000, false)
    if ok and r and r.opt >= (tonumber(arg[4]) or 30) and r.nwin == 1 then
      local ok2, r2 = pcall(E.eval, def, 600000, true)
      if ok2 and r2 then
        local cs = {}
        for _, c in ipairs(lap.cells) do cs[#cs + 1] = c[1] .. "," .. c[2] end
        out:write(string.format("opt=%d n=%d hid=%.0f smart=%.3f deep=%d d1=%d d2=%d D1=%d D2=%d walk=%d ev=%d | %s | lap=%s head=%d | %s\n",
          r2.opt, r2.n, r2.hidPct, r2.smart, r2.maxDeep, r2.doors1, r2.doors2, r2.deep1, r2.deep2, r2.walk, r2.events,
          table.concat(def.grid, "|"), table.concat(cs, ";"), lap.head, r2.doorList))
        out:flush()
      end
    end
  end
end
out:close()
