-- build/l9j/gen2.lua seed N p minOpt — мутатор скелета c1 (ручного): шахта x7 (колонка (7,2), стояк (7,8)),
-- лаз над сливом (5..6,7), боковой вход к шахте на ряду 5 с тройником на уступе (6,5), полка (6,3) под заглушку.
-- Случайны остальные стены поля 11×9, место заглушки и Лапидуса, диапазон длины.
package.path = "./?.lua;" .. package.path
local E = dofile("build/l9j/eval.lua")
local VIS = dofile("build/l9j/vis.lua")
local seed, N, P, MINOPT = tonumber(arg[1] or 1), tonumber(arg[2] or 100), tonumber(arg[3] or 0.3), tonumber(arg[4] or 26)
math.randomseed(seed)
local W, H = 11, 9
local FIX = {
  ["7,2"] = ".", ["7,3"] = ".", ["7,4"] = ".", ["7,5"] = ".", ["7,6"] = ".", ["7,7"] = ".", ["7,8"] = ".",
  ["5,7"] = ".", ["6,7"] = ".", ["5,8"] = "~", ["6,8"] = "~", ["6,6"] = "#", ["5,6"] = ".", ["5,5"] = ".", ["6,5"] = ".",
  ["6,3"] = ".", ["6,4"] = "#", ["4,8"] = "#",
}
local LENS = { { 2, 5 }, { 3, 5 }, { 3, 6 }, { 2, 6 }, { 2, 4 }, { 3, 4 }, { 4, 6 }, { 4, 5 } }
local out = io.open("build/l9j/gen2_" .. seed .. ".txt", "w")
local stat = {}
for it = 1, N do
  local g = {}
  for y = 1, H do g[y] = {} for x = 1, W do
    local f = FIX[x .. "," .. y]
    if f then g[y][x] = f
    elseif x == 1 or x == W or y == 1 or y == H or y == 2 or y == 8 then g[y][x] = "#"
    else g[y][x] = (math.random() < P) and "#" or "." end
  end end
  local function free(x, y) return g[y] and g[y][x] == "." and not (x == 7) end
  local px, py
  for _ = 1, 60 do local x, y = math.random(2, W - 1), math.random(3, 7); if free(x, y) and not (x == 6 and y == 5) then px, py = x, y break end end
  local len = LENS[math.random(#LENS)]
  local L = math.random(len[1], len[2])
  local cells
  for _ = 1, 100 do
    local x, y = math.random(2, W - 1), math.random(3, 7)
    local dir = math.random(4)
    local c, ok = {}, true
    local cx, cy = x, y
    for k = 1, L do
      if not free(cx, cy) or (cx == px and cy == py) or (cx == 6 and cy == 5) then ok = false break end
      for _, o in ipairs(c) do if o[1] == cx and o[2] == cy then ok = false end end
      if not ok then break end
      c[#c + 1] = { cx, cy }
      local d = (math.random() < 0.7) and dir or math.random(4)
      cx, cy = cx + ({ 0, 1, 0, -1 })[d], cy + ({ -1, 0, 1, 0 })[d]
    end
    if ok then cells = c break end
  end
  if px and cells then
    local rows = {}
    for y = 1, H do rows[y] = table.concat(g[y]) end
    local head = (math.random() < 0.5) and #cells or 1
    local def = {
      id = 9, visibleLoss = VIS, length = len, pressure = 0, grid = rows,
      objects = {
        { kind = "fixture", what = "heater", at = { 7, 2 }, ports = { down = "N" } },
        { kind = "source", at = { 7, 8 }, ports = { up = "N" } },
        { kind = "fitting", what = "tee", tag = "tee", at = { 6, 5 }, ports = { up = "V", down = "V", left = "N" } },
        { kind = "fitting", what = "plug", tag = "plug", at = { px, py }, ports = { right = "V" } },
        { kind = "lapidus", cells = cells, head = head },
      },
    }
    local ok, r, why = pcall(E.eval, def, 400000, false)
    if not ok then r, why = nil, "error" end
    local key = r and "sol" or why
    stat[key] = (stat[key] or 0) + 1
    if r and r.opt >= MINOPT and r.nwin <= 2 then
      local r2 = E.eval(def, 800000, true)
      if r2 then
        local cs = {}
        for _, c in ipairs(cells) do cs[#cs + 1] = c[1] .. "," .. c[2] end
        out:write(string.format("opt=%d n=%d hid=%.0f smart=%.3f deep=%d d1=%d d2=%d D1=%d D2=%d nwin=%d | %s | L=%d-%d tee=6,5 plug=%d,%d lap=%s head=%d | %s\n",
          r2.opt, r2.n, r2.hidPct, r2.smart, r2.maxDeep, r2.doors1, r2.doors2, r2.deep1, r2.deep2, r2.nwin,
          table.concat(rows, "|"), len[1], len[2], px, py, table.concat(cs, ";"), head, r2.doorList))
        out:flush()
      end
    end
  end
end
for k, v in pairs(stat) do print(k, v) end
out:close()
