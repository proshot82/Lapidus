-- build/l6c/a_f2plus/play.lua файл.lua "hu hr fl ..." — проиграть ходы с кадрами и живостью (только вывод инструмента).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local SYM = { source = "S", fixture = "F", stub = "T", pipe = "=", fitting = "b", porcelain = "P" }
local function show(s)
  local rows = {}
  for y = 1, lvl.H do rows[y] = {} for x = 1, lvl.W do local c = lvl.cell[(y-1)*lvl.W+x]; rows[y][x] = c == 1 and "#" or (c == 2 and "~" or ".") end end
  for q, pp in ipairs(lvl.pieces) do if s.pos[q] ~= 0 then local x, y = R.xy(lvl, s.pos[q]); local ch = SYM[pp.kind]; if pp.movable then ch = (pp.tag or "b"):sub(1,1); ch = s.fixed[q] and ch:upper() or ch:lower() end; rows[y][x] = ch end end
  if not s.dead then for i, c in ipairs(s.body) do local x, y = R.xy(lvl, c); rows[y][x] = (i == #s.body) and "H" or ((i == 1) and "f" or "o") end end
  local out = {}
  for y = 1, lvl.H do out[#out+1] = table.concat(rows[y]) end
  return out
end
local function status(s)
  local k = R.key(s); local id = G.index[k]
  if not id then return "?" end
  if G.flag[id] == 1 then return "WIN" end
  if G.flag[id] == 2 then return "WASH" end
  local vl = false
  for q, p in ipairs(lvl.pieces) do if p.movable and s.pos[q] == 0 then vl = true end end
  if def.visibleLoss and def.visibleLoss(lvl, s) then vl = true end
  return (good[id] == 1 and "ok" or (vl and "vis" or "HID")) .. G.depth[id] .. ""
end
local st = R.newState(lvl)
local frames = { { "start " .. status(st), show(st) } }
local W = { h = "head", f = "heel" }
local D = { u = 1, r = 2, d = 3, l = 4 }
for m in (arg[2] or ""):gmatch("%S+") do
  local ns, why = R.move(lvl, st, W[m:sub(1,1)], D[m:sub(2,2)])
  if not ns then frames[#frames+1] = { m .. " NO:" .. tostring(why), show(st) } else st = ns; frames[#frames+1] = { m .. " " .. status(st), show(st) } end
end
local per = math.max(1, math.floor(120 / (lvl.W + 3)))
for k = 1, #frames, per do
  for line = 0, lvl.H do
    local parts = {}
    for j = k, math.min(k + per - 1, #frames) do
      local t = line == 0 and frames[j][1] or frames[j][2][line]
      parts[#parts+1] = string.format("%-" .. (lvl.W + 3) .. "s", t:sub(1, lvl.W + 2))
    end
    print(table.concat(parts))
  end
  print()
end
