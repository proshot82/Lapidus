-- build/l9v/rest.lua файл.lua — какие классы скрытых остаются после правил W+T+S (build/l9v/alt.lua) и карман 3/4/5/6
-- по линейке и по линейке+W+T+S. Только метрики.
local L = dofile("build/l9v/lib.lua")
local R, V = L.R, L.V
local path = arg[1]
local def = dofile(path)
local lvl = R.compile(def)
local G = L.SV.explore(lvl, 3000000)
local good = L.SV.goodSet(G)
local W = lvl.W
local function idx(x, y) return (y - 1) * W + x end
local tags = {}
for q, p in ipairs(lvl.pieces) do if p.tag then tags[p.tag] = q end end
local function occ(s) local t = {} for q = 1, #s.pos do if s.pos[q] ~= 0 then t[s.pos[q]] = q end end return t end
local function ruleW(s)
  local o = occ(s)
  for q, p in ipairs(lvl.pieces) do if p.movable and s.pos[q] ~= 0 and s.fixed[q] then
    for d = 1, 4 do if p.ports[d] then
      local t = lvl.nb[s.pos[q]][d]
      if t == 0 or lvl.cell[t] == R.WALL then return true end
      local r = o[t]
      if r and s.fixed[r] and not R.match(p.ports[d], lvl.pieces[r].ports[R.OPP[d]]) then return true end
    end end end end
  return false
end
local function ruleT(s) local o = occ(s); local q = o[idx(9, 7)]; return q and s.fixed[q] and lvl.pieces[q].ports[R.RIGHT] ~= "V" or false end
local function ruleS(s)
  local o = occ(s)
  local bodyMinX = 99
  for _, c in ipairs(s.body) do local x, y = R.xy(lvl, c)
    if (y == 5 and x <= 5) or (x == 2 and (y == 6 or y == 7)) or y == 8 then bodyMinX = math.min(bodyMinX, (y == 5) and x or 0) end end
  for _, tg in ipairs({ "tee", "plug" }) do local q = tags[tg]
    if q and s.pos[q] ~= 0 and not s.fixed[q] then
      local x, y = R.xy(lvl, s.pos[q])
      local stacked = (x == 6 and y == 4 and o[idx(6, 5)] and not s.fixed[o[idx(6, 5)]])
      if ((y == 5 and x <= 6) or stacked) and not (bodyMinX < (stacked and 6 or x)) then return true end
    end end
  return false
end
local extra, extraWT = {}, {}
for i = 1, G.n do if G.flag[i] ~= 2 then local s = R.decode(lvl, G.keys[i]); extraWT[i] = ruleW(s) or ruleT(s); extra[i] = extraWT[i] or ruleS(s) end end
for _, P in ipairs({ 3, 4, 5, 6 }) do
  V.POCKET = P
  local VL = V.compute(lvl, G, def, good)
  local a = V.measure(G, good, VL.newbie)
  local arr = {}
  for i = 1, G.n do if G.flag[i] ~= 2 then arr[i] = VL.newbie[i] or (extra[i] and good[i] ~= 1) end end
  local b = V.measure(G, good, arr)
  local arr2 = {}
  for i = 1, G.n do if G.flag[i] ~= 2 then arr2[i] = VL.newbie[i] or (extraWT[i] and good[i] ~= 1) end end
  local c = V.measure(G, good, arr2)
  print(string.format("карман %d: линейка %.1f %% (обез %.3f, у пути [%s]) | линейка+W+T %.1f %% (у пути [%s]) | линейка+W+T+S %.1f %% (обез %.3f, у пути [%s])", P, a.hiddenPct, a.smart, a.deepList, c.hiddenPct, c.deepList, b.hiddenPct, b.smart, b.deepList))
  if P == 4 then
    -- оставшиеся классы
    local S = { lvl = lvl }
    local agg = {}
    for i = 1, G.n do if G.flag[i] ~= 2 and good[i] ~= 1 and not arr[i] then
      local s = R.decode(lvl, G.keys[i])
      local w = R.water(lvl, s)
      local wet = false
      for q, p in ipairs(lvl.pieces) do if p.kind == "pipe" and w.wet[q] then wet = true end end
      local t = {}
      for q, p in ipairs(lvl.pieces) do if p.movable and s.pos[q] ~= 0 and s.fixed[q] then local x, y = R.xy(lvl, s.pos[q]); t[#t+1] = p.tag .. "@" .. x .. "," .. y end end
      local k = (wet and "мокро " or "сухо ") .. (#t > 0 and table.concat(t, " ") or "ничего не закреплено")
      agg[k] = (agg[k] or 0) + 1
    end end
    local l = {}
    for k, v in pairs(agg) do l[#l+1] = { k, v } end
    table.sort(l, function(x, y) return x[2] > y[2] end)
    for _, x in ipairs(l) do print(string.format("    остаётся скрытым: %-40s %6d", x[1], x[2])) end
  end
end
V.POCKET = 4
L.SV.freeGraph(G); require("ffi").C.free(good)
