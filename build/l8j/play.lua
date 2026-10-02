-- build/l8j/play.lua файл.lua "fR fU HL ..." — ручной прогон ходов с кадрами (только вывод инструмента).
-- f = ноги (heel), H = голова (head); U/R/D/L — направление. Печатает причину отказа хода.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local def = dofile(arg[1])
local lvl = R.compile(def)
local errs = R.validate(lvl)
if #errs > 0 then print("ОШИБКИ: " .. table.concat(errs, "; ")) return end
local st = R.newState(lvl)
local SYM = { source = "S", fixture = "F", stub = "T", pipe = "=", fitting = "b", porcelain = "P" }
local function show(s, label)
  local rows = {}
  for y = 1, lvl.H do rows[y] = {} for x = 1, lvl.W do local c = lvl.cell[(y-1)*lvl.W+x]; rows[y][x] = c == 1 and "#" or (c == 2 and "~" or ".") end end
  for q, pp in ipairs(lvl.pieces) do if s.pos[q] ~= 0 then local x, y = R.xy(lvl, s.pos[q]); local ch = SYM[pp.kind]; if pp.movable then ch = s.fixed[q] and ch:upper() or ch:lower() end; rows[y][x] = ch end end
  if not s.dead then for i, c in ipairs(s.body) do local x, y = R.xy(lvl, c); rows[y][x] = (i == #s.body) and "H" or ((i == 1) and "f" or "o") end end
  local out = { label }
  for y = 1, lvl.H do out[#out+1] = table.concat(rows[y]) end
  return out
end
local frames = { show(st, "start") }
local DIRS = { U = 1, R = 2, D = 3, L = 4 }
local n = 0
for tok in (arg[2] or ""):gmatch("%S+") do
  local w, d = tok:sub(1,1), tok:sub(2,2)
  local which = (w == "f") and "heel" or "head"
  local ns, kind = R.move(lvl, st, which, DIRS[d])
  n = n + 1
  if not ns then frames[#frames+1] = show(st, n .. tok .. " ОТКАЗ:" .. tostring(kind)) else
    st = ns
    local w2 = R.status(lvl, st)
    frames[#frames+1] = show(st, n .. tok .. (st.dead and " СМЫТ" or (w2.win and " ПОБЕДА" or "")))
  end
end
local per = math.max(1, math.floor(120 / (lvl.W + 2)))
for k = 1, #frames, per do
  for line = 1, #frames[k] do
    local parts = {}
    for j = k, math.min(k + per - 1, #frames) do parts[#parts+1] = string.format("%-" .. (lvl.W + 2) .. "s", frames[j][line] or "") end
    print(table.concat(parts, ""))
  end
  print()
end
