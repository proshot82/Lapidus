-- claims.lua файл.lua — проверка ворот 9 для семейства M: ошибка из подсказки №1 («лестница раньше стояка»)
-- достижима и ведёт в СКРЫТЫЙ тупик; печатает, за сколько ходов она достижима, долю таких состояний среди скрытых
-- и глубину блуждания внутри тупика. Решений не печатает.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local srcCatch, stubCatch
for q, p in ipairs(lvl.pieces) do
  if p.source and p.ports[1] then srcCatch = lvl.nb[p.start][1] end
  if p.kind == "stub" and p.ports[1] then stubCatch = lvl.nb[p.start][1] end
end
local function fixedAt(st, c) for k = 1, #st.pos do if st.pos[k] == c and st.fixed[k] then return true end end return false end
local function lost(st)
  for q, p in ipairs(lvl.pieces) do if p.movable and st.pos[q] == 0 then return true end end
  return def.visibleLoss and def.visibleLoss(lvl, st) or false
end
local claims = {
  { "лестница раньше стояка (на отводе муфта, стояк пуст)", function(st) return fixedAt(st, stubCatch) and not fixedAt(st, srcCatch) end },
  { "ниппель прикручен ступенькой (не в колонке)", function(st)
      for q, p in ipairs(lvl.pieces) do if p.tag == "B" and st.fixed[q] then
        local x, y = R.xy(lvl, st.pos[q]); return y ~= 3 end end
      return false end },
}
for _, cl in ipairs(claims) do
  local n, dead, vis, live, first = 0, 0, 0, 0, nil
  local hid = {}
  for i = 1, G.n do
    if G.flag[i] ~= 2 then
      local st = R.decode(lvl, G.keys[i])
      if cl[2](st) then
        n = n + 1
        if good[i] == 1 then live = live + 1 elseif lost(st) then vis = vis + 1 else dead = dead + 1; hid[i] = true end
        if not first or G.depth[i] < G.depth[first] then first = i end
      end
    end
  end
  -- глубина блуждания внутри скрытого тупика от ближайшего входа
  local maxd = 0
  if first and hid[first] then
    local d, q, h = { [first] = 0 }, { first }, 1
    while h <= #q do
      local u = q[h]; h = h + 1
      for e = G.eStart.p[u - 1], G.eStart.p[u] - 1 do
        local v = G.edges.p[e]
        if good[v] ~= 1 and d[v] == nil and G.flag[v] ~= 2 then
          local sv = R.decode(lvl, G.keys[v])
          if not lost(sv) then d[v] = d[u] + 1; if d[v] > maxd then maxd = d[v] end; q[#q + 1] = v end
        end
      end
    end
  end
  print(string.format("%s: состояний %d (живых %d, скрытых %d, видимых %d); впервые на ходу %s; глубина скрытого блуждания %d",
    cl[1], n, live, dead, vis, first and G.depth[first] or "-", maxd))
end
SV.freeGraph(G); require("ffi").C.free(good)
