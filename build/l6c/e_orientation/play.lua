-- play.lua файл.lua "HU HR FL ..." — проиграть ходы и показать кадры (ТОЛЬКО вывод инструмента, для себя).
-- H — голова, F — ноги; U/R/D/L. Без ходов — только стартовый кадр и сведения о деталях.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local def = dofile(arg[1])
local lvl = R.compile(def)
local errs, warns = R.validate(lvl)
if #errs > 0 then print("ОШИБКИ: " .. table.concat(errs, "; ")) end
for _, w in ipairs(warns) do print("warning: " .. w) end
local SYM = { source = "S", fixture = "F", stub = "T", pipe = "=", fitting = "b", porcelain = "P" }
local function show(s, label)
  local rows = {}
  for y = 1, lvl.H do rows[y] = {} for x = 1, lvl.W do local c = lvl.cell[(y-1)*lvl.W+x]; rows[y][x] = c == 1 and "#" or (c == 2 and "~" or ".") end end
  for q, pp in ipairs(lvl.pieces) do if s.pos[q] ~= 0 then local x, y = R.xy(lvl, s.pos[q]); local ch = (pp.tag and pp.tag:sub(1,1)) or SYM[pp.kind]; if pp.movable then ch = s.fixed[q] and ch:upper() or ch:lower() else ch = SYM[pp.kind] end; rows[y][x] = ch end end
  if not s.dead then for i, c in ipairs(s.body) do local x, y = R.xy(lvl, c); rows[y][x] = (i == #s.body) and "H" or ((i == 1) and "f" or "o") end end
  local out = { label }
  for y = 1, lvl.H do out[#out+1] = table.concat(rows[y]) end
  return out
end
local st = R.newState(lvl)
local frames = { show(st, "start") }
local D = { U = 1, R = 2, D = 3, L = 4 }
local k = 0
for mv in (arg[2] or ""):gmatch("%S+") do
  k = k + 1
  local which = mv:sub(1,1) == "H" and "head" or "heel"
  local ns, why = R.move(lvl, st, which, D[mv:sub(2,2)])
  if not ns then frames[#frames+1] = { k .. mv .. " X:" .. tostring(why) }; break end
  st = ns
  local w = R.status(lvl, st)
  frames[#frames+1] = show(st, k .. mv .. (st.dead and " DEAD" or "") .. (w.win and " WIN" or ""))
end
local per = math.max(1, math.floor(120 / (lvl.W + 2)))
for i = 1, #frames, per do
  for line = 1, lvl.H + 1 do
    local parts = {}
    for j = i, math.min(i + per - 1, #frames) do parts[#parts+1] = string.format("%-" .. (lvl.W + 2) .. "s", frames[j][line] or "") end
    print(table.concat(parts, ""))
  end
  print()
end
