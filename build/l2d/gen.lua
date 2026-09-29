-- build/l2d/gen.lua — случайный поиск раскладок кв. 2 «сам себе крюк» в рамке 9×10 (шахта, крючья, одна деталь).
-- luajit build/l2d/gen.lua SEED COUNT [out.txt] — печатает/дописывает прошедшие фильтр раскладки с метриками (без решений).
package.path = "./?.lua;" .. package.path
local EV = dofile("build/l2d/eval.lua")
local MK = dofile("build/l2d/mk.lua")
local R = require("core.rules")
local seed, count = tonumber(arg[1] or 1), tonumber(arg[2] or 200)
local outf = arg[3] and io.open(arg[3], "a")
math.randomseed(seed)
local function pick(t) local s = 0; for _, w in ipairs(t) do s = s + w[2] end; local r = math.random() * s; for _, w in ipairs(t) do r = r - w[2]; if r <= 0 then return w[1] end end; return t[#t][1] end

local function layout()
  local rows = { "#########" }
  local corr = pick({ { "##S....F#", 6 }, { "#S.....F#", 2 }, { "##S...F##", 2 } })
  rows[2] = corr
  for y = 3, 9 do
    local c = {}
    c[1] = "#"
    c[2] = pick({ { "#", 5 }, { "R", 2.5 }, { "r", 2.5 } })
    for x = 3, 5 do c[x] = pick({ { ".", 8 }, { "#", 1 }, { "U", 0.3 }, { "u", 0.3 }, { "D", 0.2 }, { "d", 0.2 } }) end
    c[6] = pick({ { "#", 4 }, { "L", 1.5 }, { "l", 1.5 }, { ".", 3 } })
    if c[6] == "." then c[7] = pick({ { ".", 7 }, { "#", 3 } }) else c[7] = pick({ { ".", 3 }, { "#", 7 } }) end
    if c[7] == "." then c[8] = pick({ { ".", 7 }, { "#", 3 } }) else c[8] = pick({ { ".", 2 }, { "#", 8 } }) end
    c[9] = "#"
    rows[y] = table.concat(c)
  end
  rows[10] = pick({ { "###~~~###", 6 }, { "#########", 3 }, { "##~~~~###", 1 } })
  -- опоры: клетки, под которыми стена/отвод
  local function at(x, y) return rows[y]:sub(x, x) end
  local function solid(x, y) local ch = at(x, y); return ch ~= "." and ch ~= "~" end
  local spots = {}
  for y = 3, 9 do for x = 2, 8 do if at(x, y) == "." and solid(x, y + 1) then spots[#spots + 1] = { x, y } end end end
  if #spots < 3 then return nil end
  local function set(x, y, ch) rows[y] = rows[y]:sub(1, x - 1) .. ch .. rows[y]:sub(x + 1) end
  -- Лапидус: 2–3 клетки, горизонтально на опоре или вертикально
  local s = spots[math.random(#spots)]
  local len = pick({ { 3, 6 }, { 2, 3 }, { 4, 1 } })
  local cells = { s }
  local dir = pick({ { "h+", 3 }, { "h-", 3 }, { "v", 2 } })
  for i = 2, len do
    local p = cells[i - 1]
    local nx, ny = p[1], p[2]
    if dir == "h+" then nx = nx + 1 elseif dir == "h-" then nx = nx - 1 else ny = ny - 1 end
    if not (nx >= 2 and nx <= 8 and ny >= 2 and at(nx, ny) == ".") then break end
    cells[#cells + 1] = { nx, ny }
  end
  if #cells < 2 then return nil end
  if math.random() < 0.5 then local rev = {}; for i = #cells, 1, -1 do rev[#rev + 1] = cells[i] end; cells = rev end
  local occ = {}
  for _, c in ipairs(cells) do occ[c[1] .. "," .. c[2]] = true end
  local free = {}
  for _, sp in ipairs(spots) do if not occ[sp[1] .. "," .. sp[2]] then free[#free + 1] = sp end end
  if #free == 0 then return nil end
  local cp = free[math.random(#free)]
  set(cp[1], cp[2], pick({ { "c", 4 }, { "C", 2 }, { "o", 3 }, { "O", 1 } }))
  for i, c in ipairs(cells) do set(c[1], c[2], tostring(i)) end
  return rows
end

local seen, tried, passed = {}, 0, 0
STAT = {}
for it = 1, count do
  local rows = layout()
  if rows then
    local key = table.concat(rows, "|")
    if not seen[key] then
      seen[key] = true
      local ok, def = pcall(MK.build, rows)
      if ok then
        local ok2, lvl = pcall(R.compile, def)
        if ok2 then
          local errs, warns = R.validate(lvl)
          if #errs == 0 and #warns == 0 then
            tried = tried + 1
            local r = EV.eval(def, { fast = true, cap = 400000 })
            if r.opt then STAT.solv = (STAT.solv or 0) + 1 end
            if r.opt and r.winFixed then STAT.fixed = (STAT.fixed or 0) + 1 end
            if r.opt and r.winFixed and r.opt >= 12 then STAT.long = (STAT.long or 0) + 1 end
            if r.opt and r.winFixed and r.opt >= 12 and r.hiddenPct >= 25 then STAT.hid = (STAT.hid or 0) + 1 end
            local MINH, MAXS = tonumber(os.getenv("MINH") or 25), tonumber(os.getenv("MAXS") or 1)
            if r.opt and r.winFixed and r.opt >= 12 and r.events >= tonumber(os.getenv("MINE") or 2) and r.hiddenPct >= MINH and r.smart <= MAXS then
              passed = passed + 1
              local s = string.format("=== seed %d it %d: %s\n%s\n", seed, it, r.line, table.concat(rows, "\n"))
              print(s)
              if outf then outf:write(s, "\n"); outf:flush() end
            end
          end
        end
      end
    end
  end
end
print(string.format("seed %d: проверено %d, прошло фильтр %d; решаемых %d, деталь в сети %d, ходов>=12 %d, скрытых>=25 %d", seed, tried, passed, STAT.solv or 0, STAT.fixed or 0, STAT.long or 0, STAT.hid or 0))
