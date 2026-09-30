-- build/l8a/play.lua файл.lua [ходы…] — кадры после каждого хода (только в терминал). Ход: H|f + u|r|d|l (голова/ноги).
-- Без ходов — стартовый кадр и список допустимых ходов. Печатает струи (·), детали буквами (прикрученные — заглавными).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local def = dofile(arg[1])
local lvl = R.compile(def)
local errs, warns = R.validate(lvl)
if #errs > 0 then print("ОШИБКИ: " .. table.concat(errs, "; ")) return end
for _, w in ipairs(warns) do print("warning: " .. w) end
local SYM = { source = "S", fixture = "F", stub = "T", pipe = "=", fitting = "b", porcelain = "P" }
local function show(s, label)
  local rows = {}
  for y = 1, lvl.H do rows[y] = {} for x = 1, lvl.W do local c = lvl.cell[(y-1)*lvl.W+x]; rows[y][x] = c == 1 and "#" or (c == 2 and "~" or ".") end end
  if not s.dead then
    for _, j in ipairs(R.jets(lvl, s)) do for _, c in ipairs(j.cells) do local x, y = R.xy(lvl, c); rows[y][x] = (j.dir == R.UP) and "^" or ((j.dir == R.DOWN) and "v" or ((j.dir == R.RIGHT) and ">" or "<")) end end
  end
  for q, pp in ipairs(lvl.pieces) do if s.pos[q] ~= 0 then local x, y = R.xy(lvl, s.pos[q]); local ch = pp.movable and (pp.tag or "b"):sub(1,1) or SYM[pp.kind]; if pp.movable then ch = s.fixed[q] and ch:upper() or ch:lower() end; rows[y][x] = ch end end
  if not s.dead then for i, c in ipairs(s.body) do local x, y = R.xy(lvl, c); rows[y][x] = (i == #s.body) and "H" or ((i == 1) and "f" or "o") end end
  local out = { label }
  for y = 1, lvl.H do out[#out+1] = table.concat(rows[y]) end
  return out
end
local function legal(st)
  local t = {}
  for m = 1, 8 do local ns = R.move(lvl, st, R.MOVES[m].which, R.MOVES[m].dir); if ns then t[#t+1] = R.moveName(m):gsub("heel", "f"):gsub("head", "H"):gsub(":", ""):sub(1,2) end end
  return table.concat(t, " ")
end
local st = R.newState(lvl)
local frames = { show(st, "start") }
for i = 2, #arg do
  local w = arg[i]:sub(1,1) == "H" and "head" or "heel"
  local d = R.DIRINDEX[({u="up", r="right", d="down", l="left"})[arg[i]:sub(2,2)]]
  local ns, kind = R.move(lvl, st, w, d)
  if not ns then print("ход " .. arg[i] .. " невозможен: " .. tostring(kind)); break end
  st = ns
  local w2 = R.status(lvl, st)
  frames[#frames+1] = show(st, (i-1) .. arg[i] .. (w2.win and " WIN" or "") .. (st.dead and " DEAD" or ""))
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
print("допустимые ходы: " .. legal(st))
