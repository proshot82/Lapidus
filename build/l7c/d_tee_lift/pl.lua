-- pl.lua файл.lua "H> H^ F< ..." — проиграть ходы и показать кадры (ТОЛЬКО вывод инструмента; в файлы/ответы не переносить).
-- H — голова, F — ноги; ^ > v < — направления. Без ходов — стартовый кадр и струи.
-- Обозначения: # стена, ~ слив, S стояк, F прибор, буква тега детали (строчная — свободна, ЗАГЛАВНАЯ — закреплена),
-- H голова, f ноги, o тело, | и - струи.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local def = dofile(arg[1])
local lvl = R.compile(def)
local errs, warns = R.validate(lvl)
for _, e in ipairs(errs) do print("ОШИБКА: " .. e) end
for _, w in ipairs(warns) do print("warning: " .. w) end
local SYM = { source = "S", fixture = "F", stub = "T", pipe = "=", fitting = "b", porcelain = "P" }
local function show(s, label)
  local rows = {}
  for y = 1, lvl.H do rows[y] = {} for x = 1, lvl.W do local c = lvl.cell[(y-1)*lvl.W+x]; rows[y][x] = c == 1 and "#" or (c == 2 and "~" or ".") end end
  if not s.dead then
    for _, j in ipairs(R.jets(lvl, s)) do
      for _, c in ipairs(j.cells) do local x, y = R.xy(lvl, c); rows[y][x] = (j.dir == 1 or j.dir == 3) and "|" or "-" end
    end
  end
  for q, pp in ipairs(lvl.pieces) do if s.pos[q] ~= 0 then local x, y = R.xy(lvl, s.pos[q]); local ch
    if pp.movable then ch = (pp.tag and pp.tag:sub(1,1)) or "b"; ch = s.fixed[q] and ch:upper() or ch:lower() else ch = SYM[pp.kind] end; rows[y][x] = ch end end
  if not s.dead then for i, c in ipairs(s.body) do local x, y = R.xy(lvl, c); rows[y][x] = (i == #s.body) and "H" or ((i == 1) and "f" or "o") end end
  local out = { label }
  for y = 1, lvl.H do out[#out+1] = table.concat(rows[y]) end
  return out
end
local st = R.newState(lvl)
local frames = { show(st, "start") }
local DIR = { ["^"] = 1, [">"] = 2, ["v"] = 3, ["<"] = 4 }
local n = 0
for tok in (arg[2] or ""):gmatch("%S+") do
  local w = tok:sub(1, 1) == "H" and "head" or "heel"
  local d = DIR[tok:sub(2, 2)]
  local ns, why = R.move(lvl, st, w, d)
  n = n + 1
  if not ns then frames[#frames+1] = { n .. tok .. " НЕТ:" .. tostring(why) }
  else
    st = ns
    local s = R.status(lvl, st)
    frames[#frames+1] = show(st, n .. tok .. (st.dead and " DEAD" or "") .. (s.win and " WIN" or "") .. " L" .. #s.leaks)
  end
end
local per = math.max(1, math.floor(120 / (lvl.W + 2)))
for k = 1, #frames, per do
  for line = 1, lvl.H + 1 do
    local parts = {}
    for j = k, math.min(k + per - 1, #frames) do parts[#parts+1] = string.format("%-" .. (lvl.W + 2) .. "s", frames[j][line] or "") end
    print(table.concat(parts, ""))
  end
  print()
end
