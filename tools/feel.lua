-- tools/feel.lua — «ощущение» уровня по графу состояний, без печати решений:
-- вынужденность ходов вдоль оптимума, глубина первой возможной ошибки, размер тупиковых областей,
-- события (сдвиги деталей) и самая длинная «прогулка» без событий.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
for _, a in ipairs(arg) do
  local def = dofile(string.format("levels/%02d.lua", tonumber(a)))
  local lvl = R.compile(def)
  local G = SV.explore(lvl, 3000000)
  local good = SV.goodSet(G)
  local ngood = 0
  for i = 1, G.n do if good[i] == 1 then ngood = ngood + 1 end end
  local path, x = {}, G.firstWin
  while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
  table.insert(path, 1, 1)
  local hist, firstErr, regions, nreg = { 0, 0, 0, 0 }, nil, 0, 0
  local seenRegion = {}
  local events, streak, maxStreak = 0, 0, 0
  local function objs(k)
    local st = R.decode(lvl, k); local t = {}
    for q = 1, #st.pos do t[#t + 1] = st.pos[q] .. (st.fixed[q] and "f" or "") end
    return table.concat(t, ",")
  end
  for i = 1, #path - 1 do
    local s = path[i]
    local safe, bad = 0, 0
    for e = G.eStart.p[s - 1], G.eStart.p[s] - 1 do
      local t = G.edges.p[e]
      if good[t] == 1 then safe = safe + 1
      elseif G.flag[t] ~= 2 then
        bad = bad + 1
        if not firstErr then firstErr = i - 1 end
        if not seenRegion[t] then
          seenRegion[t] = true
          -- размер области (до 400)
          local seen, q, h, cnt = { [t] = true }, { t }, 1, 1
          while h <= #q and cnt < 400 do
            local u = q[h]; h = h + 1
            for e2 = G.eStart.p[u - 1], G.eStart.p[u] - 1 do
              local v = G.edges.p[e2]
              if not seen[v] then seen[v] = true; q[#q + 1] = v; cnt = cnt + 1 end
            end
          end
          regions, nreg = regions + cnt, nreg + 1
        end
      end
    end
    hist[math.min(safe, 4)] = hist[math.min(safe, 4)] + 1
    if objs(G.keys[path[i]]) ~= objs(G.keys[path[i + 1]]) then events = events + 1; streak = 0 else streak = streak + 1; if streak > maxStreak then maxStreak = streak end end
  end
  print(string.format("кв. %s: состояний %d (живых %d = %d%%), ходов %d | безопасных ходов на шаге: 1×%d 2×%d 3×%d ≥4×%d | первая возможная ошибка после хода %s | тупиковых областей у пути %d, средний размер %s | событий с деталями %d, дольше всего без событий %d ходов",
    a, G.n, ngood, math.floor(100 * ngood / G.n + 0.5), #path - 1, hist[1], hist[2], hist[3], hist[4], tostring(firstErr), nreg, nreg > 0 and string.format("%.0f", regions / nreg) or "—", events, maxStreak))
  SV.freeGraph(G)
end
