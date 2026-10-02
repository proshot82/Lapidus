-- build/l8a/reach.lua файл.lua [keep] — карта досягаемости (только терминал): по всем достижимым состояниям уровня
-- (без подвижных деталей, если не keep) — клетки, где бывает тело Лапидуса (o), куда входит конец ходом (e),
-- и клетки струи брандспойта (свободный конец прикрученного к мокрому) вне досягаемости тела (J); * — и то и другое.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
if arg[2] ~= "keep" then
  local o2 = {}
  for _, o in ipairs(def.objects) do if not (o.kind == "fitting" or o.kind == "porcelain") then o2[#o2 + 1] = o end end
  def.objects = o2
  def.ablations = nil
end
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local body, jet = {}, {}
for i = 1, G.n do
  if G.flag[i] ~= 2 then
    local st = R.decode(lvl, G.keys[i])
    for _, c in ipairs(st.body) do body[c] = true end
    for _, j in ipairs(R.jets(lvl, st)) do if j.lapidus then for _, c in ipairs(j.cells) do jet[c] = true end end end
    -- клетки, куда конец может войти ходом (толкнуть деталь там можно)
    for m = 1, 8 do
      local mv = R.MOVES[m]
      local b = st.body
      local e = (mv.which == "head") and b[#b] or b[1]
      local t = lvl.nb[e][mv.dir]
      if t ~= 0 and lvl.cell[t] == 0 then
        local ns = R.move(lvl, st, mv.which, mv.dir)
        if ns then body[t] = body[t] or "e" end
      end
    end
  end
end
print(string.format("состояний %d, решаем: %s", G.n, G.firstWin and ("да, " .. G.depth[G.firstWin]) or "нет"))
for y = 1, lvl.H do
  local row = {}
  for x = 1, lvl.W do
    local i = (y - 1) * lvl.W + x
    local c = lvl.cell[i]
    local ch = c == 1 and "#" or (c == 2 and "~" or ".")
    if c == 0 then
      if body[i] and jet[i] then ch = "*" elseif body[i] then ch = "o" elseif jet[i] then ch = "J" end
    end
    row[x] = ch
  end
  for _, p in ipairs(lvl.pieces) do local x, y2 = R.xy(lvl, p.start); if y2 == y and not p.movable then row[x] = ({ source = "S", fixture = "K", stub = "T", pipe = "=" })[p.kind] or "?" end end
  print(table.concat(row))
end
SV.freeGraph(G)
