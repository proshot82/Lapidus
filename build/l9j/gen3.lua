-- build/l9j/gen3.lua seed N p deep — раунд f: сеть «заглушка снизу под тройником». Колонка (7,2) вниз Н; тройник
-- В-В + Н влево входит в колонку только сбоку по полке ряда 3; заглушка (вверх Н) закрывает нижний выход тройника и
-- попадает под колонку только через верх шахты (7,3). Стояк В — слева на полке (вход вправо). deep=1: шахта глубже,
-- заглушку надо держать пяткой; deep=0: у шахты дно на ряду 5. Случайны стены левой части, места деталей и Лапидуса.
package.path = "./?.lua;" .. package.path
local E = dofile("build/l9j/eval.lua")
local VIS = dofile("build/l9j/vis9.lua")
local seed, N, P, DEEP = tonumber(arg[1] or 1), tonumber(arg[2] or 100), tonumber(arg[3] or 0.3), tonumber(arg[4] or 0)
math.randomseed(seed)
local W, H = 10, 9
local out = io.open("build/l9j/gen3_" .. seed .. ".txt", "w")
local stat = {}
for it = 1, N do
  local g = {}
  for y = 1, H do g[y] = {} for x = 1, W do
    if x == 1 or x >= 9 or y == 1 or y == 2 or y == H then g[y][x] = "#"
    else g[y][x] = (math.random() < P) and "#" or "." end
  end end
  g[2][7] = "."; g[3][7] = "."; g[4][7] = "."; g[3][6] = "."; g[4][6] = "#"; g[3][8] = "#"; g[4][8] = "#"
  if DEEP == 1 then g[5][7] = "."; g[6][7] = "."; g[7][7] = "#" else g[5][7] = "#" end
  for y = 5, 8 do g[y][8] = "#" end
  g[3][2] = "."
  local function free(x, y) return g[y] and g[y][x] == "." and x ~= 7 and not (x == 2 and y == 3) end
  local cells = {}
  for y = 3, 8 do for x = 2, 6 do if free(x, y) then cells[#cells + 1] = { x, y } end end end
  if #cells > 8 then
    local function pick() return cells[math.random(#cells)] end
    local t, p = pick(), pick()
    local L = math.random(2, 5)
    local lap
    for _ = 1, 60 do
      local c0 = pick(); local c, ok = { c0 }, true
      for k = 2, L do
        local last = c[#c]; local d = math.random(4)
        local nx, ny = last[1] + ({ 0, 1, 0, -1 })[d], last[2] + ({ -1, 0, 1, 0 })[d]
        if not free(nx, ny) then ok = false break end
        for _, o in ipairs(c) do if o[1] == nx and o[2] == ny then ok = false end end
        c[#c + 1] = { nx, ny }
      end
      for _, o in ipairs(c) do if (o[1] == t[1] and o[2] == t[2]) or (o[1] == p[1] and o[2] == p[2]) then ok = false end end
      if ok then lap = c break end
    end
    if lap and not (t[1] == p[1] and t[2] == p[2]) then
      local rows = {}
      for y = 1, H do rows[y] = table.concat(g[y]) end
      local lens = { { 2, 6 }, { 2, 5 }, { 3, 6 } }
      local len = lens[math.random(#lens)]
      if #lap >= len[1] and #lap <= len[2] then
        local def = {
          id = 9, visibleLoss = VIS, length = len, pressure = 0, grid = rows,
          objects = {
            { kind = "fixture", what = "heater", at = { 7, 2 }, ports = { down = "N" } },
            { kind = "source", at = { 2, 3 }, ports = { right = "V" } },
            { kind = "fitting", what = "tee", tag = "tee", at = t, ports = { up = "V", down = "V", left = "N" } },
            { kind = "fitting", what = "plug", tag = "plug", at = p, ports = { up = "N" } },
            { kind = "lapidus", cells = lap, head = (math.random() < 0.5) and 1 or #lap },
          },
        }
        local ok, r, why = pcall(E.eval, def, 300000, false)
        if not ok then r, why = nil, "err" end
        local key = r and "sol" or tostring(why)
        stat[key] = (stat[key] or 0) + 1
        if r and r.opt >= 26 and r.nwin == 1 then
          local ok2, r2 = pcall(E.eval, def, 600000, true)
          if ok2 and r2 then
            local cs = {}
            for _, c in ipairs(lap) do cs[#cs + 1] = c[1] .. "," .. c[2] end
            out:write(string.format("opt=%d n=%d hid=%.0f smart=%.3f deep=%d d1=%d d2=%d D1=%d D2=%d walk=%d | %s | L=%d-%d tee=%d,%d plug=%d,%d lap=%s head=%d | %s\n",
              r2.opt, r2.n, r2.hidPct, r2.smart, r2.maxDeep, r2.doors1, r2.doors2, r2.deep1, r2.deep2, r2.walk,
              table.concat(rows, "|"), len[1], len[2], t[1], t[2], p[1], p[2], table.concat(cs, ";"), def.objects[5].head, r2.doorList))
            out:flush()
          end
        end
      end
    end
  end
end
for k, v in pairs(stat) do print(k, v) end
out:close()
