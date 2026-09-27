-- build/l6/play.lua файл.lua "Hu Hr fL ..." — проиграть ходы (H голова, f ноги; u r d l), показать кадры.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local def = dofile(arg[1])
local lvl = R.compile(def)
local st = R.newState(lvl)
local SYM = { source = "S", fixture = "F", stub = "T", pipe = "=", fitting = "b", porcelain = "P" }
local function show(s, label)
  local rows = {}
  for y = 1, lvl.H do rows[y] = {} for x = 1, lvl.W do local c = lvl.cell[(y-1)*lvl.W+x]; rows[y][x] = c == 1 and "#" or (c == 2 and "~" or ".") end end
  for q, p in ipairs(lvl.pieces) do if s.pos[q] ~= 0 then local x, y = R.xy(lvl, s.pos[q]); local ch = SYM[p.kind]; if p.kind == "fitting" or p.kind == "porcelain" then ch = s.fixed[q] and ch:upper() or ch end; rows[y][x] = ch end end
  if not s.dead then for i, c in ipairs(s.body) do local x, y = R.xy(lvl, c); rows[y][x] = (i == #s.body) and "H" or ((i == 1) and "f" or "o") end end
  local out = { label }
  for y = 1, lvl.H do out[#out+1] = table.concat(rows[y]) end
  return out
end
local frames = { show(st, "start") }
local D = { u = "up", r = "right", d = "down", l = "left" }
for tok in (arg[2] or ""):gmatch("%S+") do
  local w = tok:sub(1,1) == "H" and "head" or "heel"
  local dir = R.DIRINDEX[D[tok:sub(2,2)]]
  local ns, why = R.move(lvl, st, w, dir)
  if ns then st = ns; local s = R.status(lvl, st); frames[#frames+1] = show(st, tok .. (st.dead and " DEAD" or (s.win and " WIN" or ""))) else frames[#frames+1] = show(st, tok .. " X:" .. tostring(why)) end
end
for k = 1, #frames, 8 do
  for line = 1, #frames[k] do
    local parts = {}
    for j = k, math.min(k + 7, #frames) do parts[#parts+1] = string.format("%-13s", frames[j][line] or "") end
    print(table.concat(parts, " "))
  end
  print()
end
