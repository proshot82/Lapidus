-- show.lua файл.lua [ходы через пробел, напр. "H:up f:left"] — кадры для себя (только вывод инструмента).
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
  for q, pp in ipairs(lvl.pieces) do if s.pos[q] ~= 0 then local x, y = R.xy(lvl, s.pos[q]); local ch = pp.sym or (pp.tag and pp.tag:sub(1,1)) or SYM[pp.kind]; if not pp.movable then ch = SYM[pp.kind] end; if pp.movable then ch = s.fixed[q] and ch:upper() or ch:lower() end; rows[y][x] = ch end end
  if not s.dead then for i, c in ipairs(s.body) do local x, y = R.xy(lvl, c); rows[y][x] = (i == #s.body) and "H" or ((i == 1) and "f" or "o") end end
  local out = { label }
  for y = 1, lvl.H do out[#out+1] = table.concat(rows[y]) end
  return out
end
local SV = require("solver.solve")
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local function lost(s2)
  for q, p in ipairs(lvl.pieces) do if p.movable and s2.pos[q] == 0 then return true end end
  return def.visibleLoss and def.visibleLoss(lvl, s2) or false
end
local function cls(s2)
  local id = G.index[R.key(s2)]
  if not id then return "?" end
  if G.flag[id] == 1 then return "W" end
  if G.flag[id] == 2 then return "~" end
  if good[id] == 1 then return "+" end
  return lost(s2) and "v" or "X"
end
local st = R.newState(lvl)
print("кратчайшее: " .. (G.firstWin and G.depth[G.firstWin] or "НЕРЕШАЕМ") .. ", состояний " .. G.n)
local frames = { show(st, "start" .. cls(st)) }
local k = 0
for tok in (arg[2] or ""):gmatch("%S+") do
  local w, d = tok:match("^(%a+):(%a+)$")
  local which = (w == "H" or w == "head") and "head" or "heel"
  local dir = ({ up = 1, right = 2, down = 3, left = 4, u = 1, r = 2, d = 3, l = 4 })[d]
  local ns, why = R.move(lvl, st, which, dir)
  k = k + 1
  if not ns then frames[#frames+1] = show(st, k .. "X" .. tostring(why)) else
    st = ns; frames[#frames+1] = show(st, k .. tok:gsub("heel","f"):gsub(":","") .. cls(st)) end
end
local per = math.max(1, math.floor(120 / (lvl.W + 2)))
for i = 1, #frames, per do
  for line = 1, #frames[i] do
    local parts = {}
    for j = i, math.min(i + per - 1, #frames) do parts[#parts+1] = string.format("%-" .. (lvl.W + 2) .. "s", frames[j][line] or "") end
    print(table.concat(parts, ""))
  end
  print()
end
