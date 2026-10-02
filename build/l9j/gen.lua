-- build/l9j/gen.lua seed N [p] — мутатор авторского скелета «шахта: колонка сверху, стояк снизу, лаз над сливом слева,
-- боковой вход справа». Случайны только стены вне скелета, места деталей и Лапидуса. Пишет строки-кандидаты.
package.path = "./?.lua;" .. package.path
local E = dofile("build/l9j/eval.lua")
local seed, N, P = tonumber(arg[1] or 1), tonumber(arg[2] or 100), tonumber(arg[3] or 0.3)
SKEL = tonumber(arg[5] or 1)
local VIS = dofile("build/l9j/vis.lua")
math.randomseed(seed)
local W, H = 12, 9
local function base()
  local g = {}
  for y = 1, H do g[y] = {} for x = 1, W do g[y][x] = "#" end end
  for y = 3, 7 do for x = 2, 11 do g[y][x] = "?" end end
  g[2][7] = "."
  for y = 3, 7 do g[y][7] = "." end
  g[6][5], g[6][6], g[4][6] = "#", "#", "#"
  g[7][5], g[7][6], g[3][6] = ".", ".", "."
  if SKEL == 1 then g[4][8], g[6][8], g[7][8] = "#", "#", "#"; g[5][8] = "." end
  g[8][5], g[8][6], g[8][7] = "~", "~", "."
  return g
end
local LENS = { { 2, 5 }, { 3, 5 }, { 3, 6 }, { 2, 6 }, { 2, 4 }, { 3, 4 } }
local out = io.open("build/l9j/gen_" .. seed .. ".txt", "w")
local function free(g, x, y) return g[y] and g[y][x] == "." end
for it = 1, N do
  local g = base()
  for y = 3, 7 do for x = 2, 11 do if g[y][x] == "?" then g[y][x] = (math.random() < P) and "#" or "." end end end
  -- детали
  local function pick(x1, x2)
    for _ = 1, 50 do local x, y = math.random(x1, x2), math.random(3, 7); if free(g, x, y) then return x, y end end
  end
  local tx, ty = pick(2, 11)
  if tx == 7 then tx = nil end
  local px, py = pick(2, 5)
  local len = LENS[math.random(#LENS)]
  local L = math.random(len[1], len[2])
  local cells
  for _ = 1, 80 do
    local x, y = math.random(2, 5), math.random(3, 7)
    local horiz = math.random() < 0.6
    local c, ok = {}, true
    for k = 0, L - 1 do
      local cx, cy = horiz and x + k or x, horiz and y or y + k
      if not free(g, cx, cy) or (cx == px and cy == py) or (cx == tx and cy == ty) then ok = false break end
      c[#c + 1] = { cx, cy }
    end
    if ok then cells = c break end
  end
  if tx and px and cells then
    local rows = {}
    for y = 1, H do rows[y] = table.concat(g[y]) end
    local head = (math.random() < 0.7) and #cells or 1
    local def = {
      id = 9, visibleLoss = VIS, length = len, pressure = 0, grid = rows,
      objects = {
        { kind = "fixture", what = "heater", at = { 7, 2 }, ports = { down = "N" } },
        { kind = "source", at = { 7, 8 }, ports = { up = "N" } },
        { kind = "fitting", what = "tee", tag = "tee", at = { tx, ty }, ports = { up = "V", down = "V", left = "N" } },
        { kind = "fitting", what = "plug", tag = "plug", at = { px, py }, ports = { right = "V" } },
        { kind = "lapidus", cells = cells, head = head },
      },
    }
    local r, why = E.eval(def, 300000, false)
    STAT = STAT or {}; local key = r and ("sol" .. (r.win.fixed[3] and r.win.pos[3] == 2 * W + 7 and "F" or "S")) or why; STAT[key] = (STAT[key] or 0) + 1
    if r then OPTS = OPTS or {}; OPTS[#OPTS+1] = r.opt end
    if r and r.opt >= (tonumber(arg[4]) or 24) then
      local teeF = r.win.fixed[3] and r.win.pos[3] == (3 - 1) * W + 7
      if teeF then
        local r2 = E.eval(def, 600000, true)
        if r2 then
          local cs = {}
          for _, c in ipairs(cells) do cs[#cs + 1] = c[1] .. "," .. c[2] end
          out:write(string.format("opt=%d n=%d hid=%.0f smart=%.3f deep=%d d1=%d d2=%d D1=%d D2=%d nwin=%d | %s | L=%d-%d tee=%d,%d plug=%d,%d lap=%s head=%d | %s\n",
            r2.opt, r2.n, r2.hidPct, r2.smart, r2.maxDeep, r2.doors1, r2.doors2, r2.deep1, r2.deep2, r2.nwin,
            table.concat(rows, "|"), len[1], len[2], tx, ty, px, py, table.concat(cs, ";"), head, r2.doorList))
          out:flush()
        end
      end
    end
  end
end
out:close()
for k, v in pairs(STAT or {}) do print(k, v) end; table.sort(OPTS or {}); print(table.concat(OPTS or {}, " "))
