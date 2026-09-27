-- tools/frames.lua — отладка кандидатов: кадры кратчайшего решения (только для черновиков, не для готовых уровней).
-- luajit tools/frames.lua список.lua N [ablation#]
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local S = require("core.search")
local SV = require("solver.solve")
local list = dofile(arg[1])
local def = list.grid and list or list[tonumber(arg[2] or "1")]
if arg[3] then def = SV.applyAblation(SV.deepcopy(def), def.ablations[tonumber(arg[3])]); def.ablations = nil end
local lvl = R.compile(def)
local st = R.newState(lvl)
local res, path = S.run(lvl, st, 3000000)
print("result", res, path and #path)
local SYM = { source = "S", fixture = "F", stub = "T", pipe = "=", fitting = "b", porcelain = "P" }
local function show(s, label)
  local rows = {}
  for y = 1, lvl.H do rows[y] = {} for x = 1, lvl.W do local c = lvl.cell[(y-1)*lvl.W+x]; rows[y][x] = c == 1 and "#" or (c == 2 and "~" or ".") end end
  for q, p in ipairs(lvl.pieces) do if s.pos[q] ~= 0 then local x, y = R.xy(lvl, s.pos[q]); local ch = SYM[p.kind]; if p.what == "tee" then ch = s.fixed[q] and "T" or "t" elseif p.what == "plug" then ch = s.fixed[q] and "Z" or "z" end; rows[y][x] = ch end end
  for i, c in ipairs(s.body) do local x, y = R.xy(lvl, c); rows[y][x] = (i == #s.body) and "H" or ((i == 1) and "f" or "o") end
  local out = { label }
  for y = 1, lvl.H do out[#out+1] = table.concat(rows[y]) end
  return out
end
if path then
  local frames = { show(st, "start") }
  for i, m in ipairs(path) do st = R.move(lvl, st, R.MOVES[m].which, R.MOVES[m].dir); frames[#frames+1] = show(st, i .. (R.MOVES[m].which == "head" and "H" or "f") .. R.DIRNAME[R.MOVES[m].dir]:sub(1,1)) end
  for k = 1, #frames, 8 do
    for line = 1, #frames[k] do
      local parts = {}
      for j = k, math.min(k + 7, #frames) do parts[#parts+1] = string.format("%-13s", frames[j][line]) end
      print(table.concat(parts, " "))
    end
    print()
  end
end
