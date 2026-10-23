-- build/p6/neck/show.lua файл.lua [ходы...] — без ходов: кадры кратчайшего решения; с ходами (hu hd hl hr fu fd fl fr):
-- проиграть их и показать кадры с пометкой живое/тупик. Только вывод инструмента.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = G.firstWin and SV.goodSet(G) or nil
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
local function status(st)
  local k = R.key(st); local id = G.index[k]
  if not id then return "?" end
  if G.flag[id] == 1 then return "WIN" end
  if G.flag[id] == 2 then return "WASH" end
  return good[id] == 1 and "" or "!"
end
local frames = {}
local st = R.newState(lvl)
frames[1] = show(st, "start")
if #arg >= 2 then
  local map = { h = "head", f = "heel" }
  local dm = { u = 1, r = 2, d = 3, l = 4 }
  for i = 2, #arg do
    local a = arg[i]
    local ns, why = R.move(lvl, st, map[a:sub(1,1)], dm[a:sub(2,2)])
    if not ns then frames[#frames+1] = show(st, (i-1) .. a .. "X:" .. why) else st = ns; frames[#frames+1] = show(st, (i-1) .. a .. status(st)) end
  end
else
  if not G.firstWin then print("НЕРЕШАЕМ", G.n) return end
  local path, x = {}, G.firstWin
  while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
  for i, id in ipairs(path) do
    local s = R.decode(lvl, G.keys[id])
    local m = R.MOVES[G.pmove[id]]
    frames[#frames+1] = show(s, i .. (m.which == "head" and "h" or "f") .. R.DIRNAME[m.dir]:sub(1,1) .. (good[id] == 1 and "" or "!"))
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
