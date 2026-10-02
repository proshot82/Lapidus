-- build/l7e/batch.lua файл1.lua файл2.lua ... — сводка по кандидатам: ворота (как check.lua, коротко) + входы в скрытые
-- тупики из живых состояний (типов входов, из них с хвостом ≥ 8; глубины входов). Кадров и ходов не печатает.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local ST = require("solver.strict")
local V = require("tools.vislib")
local function cfg(lvl, s)
  local t = {}
  for q, p in ipairs(lvl.pieces) do if p.movable then
    if s.pos[q] == 0 then t[#t+1] = p.tag .. "=смыт" else
    local x, y = R.xy(lvl, s.pos[q]); t[#t+1] = string.format("%s(%d,%d)%s", p.tag, x, y, s.fixed[q] and "F" or "") end end end
  return table.concat(t, " ")
end
for _, f in ipairs(arg) do
  local ok, def = pcall(dofile, f)
  local name = f:match("([^/]+)%.lua$")
  if not ok then print(name, "ошибка", def) else
  local lvl = R.compile(def)
  local G = SV.explore(lvl, 3000000)
  if not G or not G.firstWin then print(string.format("%-6s НЕРЕШАЕМ (%d)", name, G and G.n or -1)) else
    local good = SV.goodSet(G)
    local VL = V.compute(lvl, G, def, good)
    local m = V.measure(G, good, VL.newbie)
    local nwin = 0; for i = 1, G.n do if G.flag[i] == 1 then nwin = nwin + 1 end end
    local function depthFrom(j)
      local d, q, h, maxd = { [j] = 0 }, { j }, 1, 0
      while h <= #q do local u = q[h]; h = h + 1
        for e = G.eStart.p[u-1], G.eStart.p[u]-1 do local v = G.edges.p[e]
          if m.hidden[v] and d[v] == nil then d[v] = d[u]+1; if d[v] > maxd then maxd = d[v] end; q[#q+1] = v end end end
      return maxd
    end
    local agg = {}
    for i = 1, G.n do if good[i] == 1 then
      for e = G.eStart.p[i-1], G.eStart.p[i]-1 do local j = G.edges.p[e]
        if m.hidden[j] then
          local k = cfg(lvl, VL.states[i]) .. "→" .. cfg(lvl, VL.states[j])
          local a = agg[k] or { minD = 999, tail = 0 }; agg[k] = a
          if G.depth[i] < a.minD then a.minD = G.depth[i] end
          local t = depthFrom(j); if t > a.tail then a.tail = t end
        end end end end
    local ne, deep, ds = 0, 0, {}
    for k, a in pairs(agg) do ne = ne + 1; if a.tail >= 8 then deep = deep + 1; ds[#ds+1] = a.minD .. ":" .. a.tail end end
    table.sort(ds, function(x, y) return tonumber(x:match("^(%d+)")) < tonumber(y:match("^(%d+)")) end)
    local sx = ST.check(def, 3000000)
    local abl = SV.ablations(def, { cap = 3000000 })
    local nab, bad = 0, {}
    for _, a in ipairs(abl) do nab = nab + 1; if a.solvable ~= false then bad[#bad+1] = a.name end end
    -- прогулка и события
    local path, x = {}, G.firstWin
    while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
    table.insert(path, 1, 1)
    local function objs(i) local st = R.decode(lvl, G.keys[i]); local t = {}; for q = 1, #st.pos do t[#t+1] = st.pos[q] .. (st.fixed[q] and "f" or "") end; return table.concat(t, ",") end
    local streak, maxStreak, events = 0, 0, 0
    for i = 1, #path - 1 do
      if objs(path[i]) ~= objs(path[i+1]) then events = events + 1; streak = 0 else streak = streak + 1; if streak > maxStreak then maxStreak = streak end end
    end
    print(string.format("%-6s ходов %2d сост %6d выигр %d СКРЫТЫХ %4.1f%% обезьяна %.2f глубина %2d [%s] наобум %.3f крат %d/шир %d соб %d прог %d | входов %d (глубоких %d: %s)%s",
      name, m.opt, G.n, nwin, m.hiddenPct, m.smart, m.maxDeep, m.deepList, sx and sx.monkey or -1, sx and sx.shortest or -1, sx and sx.maxWidth or -1,
      events, maxStreak, ne, deep, table.concat(ds, " "), #bad > 0 and (" АБЛЯЦИИ РЕШАЕМЫ: " .. table.concat(bad, "; ")) or ""))
    SV.freeGraph(G); require("ffi").C.free(good)
  end end
end
