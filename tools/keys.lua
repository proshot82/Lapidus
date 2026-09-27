-- tools/keys.lua — «ключевые точки» уровня без печати решения: состояния на оптимальном пути, без которых
-- победа недостижима (все выигрышные пути проходят через них), и что в них происходит (деталь / крепление).
-- luajit tools/keys.lua 1 2 3
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
for _, a in ipairs(arg) do
  local def = dofile(string.format("levels/%02d.lua", tonumber(a)))
  local lvl = R.compile(def)
  local G = SV.explore(lvl, 3000000)
  local E, ES = G.edges.p, G.eStart.p
  local path, x = {}, G.firstWin
  while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
  table.insert(path, 1, 1)
  local function reachWinAvoiding(avoid)
    local seen, q, h = { [1] = true, [avoid] = true }, { 1 }, 1
    while h <= #q do
      local s = q[h]; h = h + 1
      if G.flag[s] == 1 then return true end
      for e = ES[s - 1], ES[s] - 1 do local t = E[e]; if not seen[t] then seen[t] = true; q[#q + 1] = t end end
    end
    return false
  end
  local function objs(k)
    local st = R.decode(lvl, k); local t = {}
    for q = 1, #st.pos do t[#t + 1] = st.pos[q] .. (st.fixed[q] and "f" or "") end
    local piece = R.occupancy(st)
    local anch = (R.endScrew(lvl, st, piece, "head") and "Г" or "") .. (R.endScrew(lvl, st, piece, "heel") and "Н" or "")
    return table.concat(t, ","), anch
  end
  local keys = {}
  for i = 2, #path - 1 do
    local s = path[i]
    if not reachWinAvoiding(s) then
      local o1, a1 = objs(G.keys[path[i - 1]])
      local o2, a2 = objs(G.keys[s])
      local what = (o1 ~= o2) and "деталь" or ((a1 ~= a2) and ("крепление " .. (a2 ~= "" and a2 or "снято")) or "положение")
      keys[#keys + 1] = string.format("%d:%s", i - 1, what)
    end
  end
  print(string.format("кв. %s: ходов %d, ключевых точек %d — %s", a, #path - 1, #keys, table.concat(keys, "  ")))
  SV.freeGraph(G)
end
