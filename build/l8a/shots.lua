-- build/l8a/shots.lua файл.lua [keep] — куда может бить брандспойт (по всем достижимым состояниям, без подвижных деталей,
-- если не keep): для каждого якоря (номер детали) — карта клеток струи со стрелкой направления (< > ^ v; * — несколько);
-- o — клетки, куда входит конец ходом (тело может толкнуть). Только терминал.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
if arg[2] ~= "keep" then
  local o2 = {}
  for _, o in ipairs(def.objects) do if not (o.kind == "fitting" or o.kind == "porcelain") then o2[#o2 + 1] = o end end
  def.objects = o2
end
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local jets, body = {}, {}
local AR = { "^", ">", "v", "<" }
for i = 1, G.n do
  if G.flag[i] ~= 2 then
    local st = R.decode(lvl, G.keys[i])
    local w = R.water(lvl, st)
    for _, j in ipairs(R.jets(lvl, st)) do
      if j.lapidus then
        local a = (w.headQ or w.heelQ) .. (j.lapidus == "head" and "H" or "f")
        jets[a] = jets[a] or {}
        for _, c in ipairs(j.cells) do
          local m = jets[a][c]
          jets[a][c] = (m == nil or m == AR[j.dir]) and AR[j.dir] or "*"
        end
      end
    end
    for m = 1, 8 do
      local mv = R.MOVES[m]
      local b = st.body
      local e = (mv.which == "head") and b[#b] or b[1]
      local t = lvl.nb[e][mv.dir]
      if t ~= 0 and lvl.cell[t] == 0 and R.move(lvl, st, mv.which, mv.dir) then body[t] = true end
    end
  end
end
print(string.format("состояний %d", G.n))
for q, p in ipairs(lvl.pieces) do local x, y = R.xy(lvl, p.start); print(q, p.kind, x, y) end
local function show(title, map)
  print("== " .. title)
  for y = 1, lvl.H do
    local row = {}
    for x = 1, lvl.W do
      local i = (y - 1) * lvl.W + x
      local c = lvl.cell[i]
      local ch = c == 1 and "#" or (c == 2 and "~" or ".")
      if c == 0 then if map and map[i] then ch = map[i] elseif (not map) and body[i] then ch = "o" end end
      row[x] = ch
    end
    for _, p in ipairs(lvl.pieces) do local x, y2 = R.xy(lvl, p.start); if y2 == y then row[x] = ({ source = "S", fixture = "K", stub = "T", pipe = "=" })[p.kind] or "?" end end
    print(table.concat(row))
  end
end
show("тело (конец входит)", nil)
for a, map in pairs(jets) do show("струя, якорь " .. a, map) end
SV.freeGraph(G)
