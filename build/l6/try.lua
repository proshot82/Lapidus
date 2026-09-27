-- build/l6/try.lua — черновой прогон кандидата кв. 6: метрики, строгие ворота, абляции, «ощущение».
-- luajit build/l6/try.lua файл.lua [frames]
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local ST = require("solver.strict")
local def = dofile(arg[1])
local res = SV.analyze(def, { cap = 3000000, keepGraph = true })
print(SV.summary(res))
for _, w in ipairs(res.warnings or {}) do print("  warning: " .. w) end
if res.solvable then
  local abl = SV.ablations(def, { cap = 3000000 })
  local ab = {}
  for _, a in ipairs(abl) do ab[#ab + 1] = a.name .. "=" .. (a.solvable == false and "нет" or tostring(a.solvable)) end
  print("абляции: " .. table.concat(ab, ", "))
  local sx = ST.check(def, 3000000)
  if sx then print(string.format("строго: наобум %.3f %%; кратчайших %d (ширина %d, развилок %d)", sx.monkey, sx.shortest, sx.maxWidth, sx.spread)) end
  -- ощущение
  local lvl = R.compile(def)
  local G = res.graph
  local good = SV.goodSet(G)
  local path, x = {}, G.firstWin
  while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
  table.insert(path, 1, 1)
  local hist, firstErr, nreg, regs = { [0]=0, 0, 0, 0, 0 }, nil, 0, {}
  local events, streak, maxStreak = 0, 0, 0
  local seenR = {}
  local function objs(k) local st = R.decode(lvl, k); local t = {}; for q = 1, #st.pos do t[#t+1] = st.pos[q] .. (st.fixed[q] and "f" or "") end; return table.concat(t, ",") end
  local safeSeq = {}
  for i = 1, #path - 1 do
    local s = path[i]
    local safe = 0
    for e = G.eStart.p[s-1], G.eStart.p[s]-1 do
      local t = G.edges.p[e]
      if good[t] == 1 then safe = safe + 1 elseif G.flag[t] ~= 2 then
        if not firstErr then firstErr = i - 1 end
        if not seenR[t] then seenR[t] = true
          local seen, q, h, cnt = { [t] = true }, { t }, 1, 1
          while h <= #q and cnt < 2000 do local u = q[h]; h = h + 1
            for e2 = G.eStart.p[u-1], G.eStart.p[u]-1 do local v = G.edges.p[e2]; if not seen[v] then seen[v] = true; q[#q+1] = v; cnt = cnt + 1 end end end
          nreg = nreg + 1; regs[#regs+1] = cnt
        end
      end
    end
    safeSeq[#safeSeq+1] = safe
    hist[math.min(safe, 4)] = (hist[math.min(safe, 4)] or 0) + 1
    if objs(G.keys[path[i]]) ~= objs(G.keys[path[i+1]]) then events = events + 1; streak = 0 else streak = streak + 1; if streak > maxStreak then maxStreak = streak end end
  end
  table.sort(regs, function(a,b) return a > b end)
  local rr = {}
  for i = 1, math.min(8, #regs) do rr[#rr+1] = regs[i] end
  print(string.format("ощущение: безопасных на шаге 1×%d 2×%d 3×%d ≥4×%d; первая ошибка после %s; ловушек у пути %d (размеры %s); событий %d; прогулка max %d",
    hist[1], hist[2], hist[3], hist[4], tostring(firstErr), nreg, table.concat(rr, " "), events, maxStreak))
  print("безопасных ходов по шагам: " .. table.concat(safeSeq, ""))
  SV.freeGraph(G); require("ffi").C.free(good)
end
