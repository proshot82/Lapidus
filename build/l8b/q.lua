-- build/l8b/q.lua файл… — быстрая сводка кандидата: решаем/ходов/состояний, скрытых % (новичок), двери с пути по половинам,
-- обезьяна, прогулка, абляции (без деталей и фильтры). Ходы не печатает. Аргумент -n: без абляций.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local noabl, files = false, {}
for _, a in ipairs(arg) do if a == "-n" then noabl = true else files[#files + 1] = a end end
for _, f in ipairs(files) do
  local def = dofile(f)
  local lvl = R.compile(def)
  local errs = R.validate(lvl)
  local name = f:match("([^/]+)%.lua$")
  if #errs > 0 then print(name, "ОШИБКИ", table.concat(errs, "; ")) else
  local t0 = os.clock()
  local G = SV.explore(lvl, 3000000)
  if not G then print(name, "CAP") else
  if not G.firstWin then print(string.format("%-6s НЕРЕШАЕМ (состояний %d, %.0fs)", name, G.n, os.clock() - t0))
  else
    local good = SV.goodSet(G)
    local VL = V.compute(lvl, G, def, good)
    local m = V.measure(G, good, VL.newbie)
    local ES, E = G.eStart.p, G.edges.p
    local nwin = 0
    for i = 1, G.n do if G.flag[i] == 1 then nwin = nwin + 1 end end
    -- двери с кратчайшего пути (первого найденного) по шагам
    local doors = {}
    for k = 1, #m.path - 1 do
      local s, c = m.path[k], 0
      for e = ES[s - 1], ES[s] - 1 do if m.hidden[E[e]] then c = c + 1 end end
      if c > 0 then doors[#doors + 1] = (k - 1) .. ":" .. c end
    end
    -- события и прогулка
    local function objs(i) local st = R.decode(lvl, G.keys[i]); local t = {}; for q = 1, #st.pos do t[#t+1] = st.pos[q] .. (st.fixed[q] and "f" or "") end; return table.concat(t, ",") end
    local streak, maxStreak, events = 0, 0, 0
    for i = 1, #m.path - 1 do
      if objs(m.path[i]) ~= objs(m.path[i + 1]) then events = events + 1; streak = 0 else streak = streak + 1; if streak > maxStreak then maxStreak = streak end end
    end
    print(string.format("%-6s ходов %2d сост %7d жив %6d вид %6d скр %6d (%.1f %%) выигр %d | обез %.2f глуб %d [%s] | соб %d прог %d | двери с пути: %s | %.0fs",
      name, m.opt, G.n, m.live, m.vis, m.hid, m.hiddenPct, nwin, m.smart, m.maxDeep, m.deepList, events, maxStreak,
      #doors > 0 and table.concat(doors, " ") or "нет", os.clock() - t0))
    require("ffi").C.free(good)
    if not noabl then
      local abl = SV.ablations(def, { cap = 3000000 })
      local t = {}
      for _, a in ipairs(abl) do t[#t + 1] = a.name .. "=" .. (a.solvable == false and "нерешаем" or "РЕШАЕМ") end
      print("       абляции: " .. table.concat(t, ", "))
      for _, c in ipairs(def.controls or {}) do
        local d2 = SV.deepcopy(def); d2.ablations = nil; d2.controls = nil
        SV.applyAblation(d2, c)
        local G2 = SV.explore(R.compile(d2), 3000000, c.filter)
        print(string.format("       контроль «%s»: %s", c.name, G2 and G2.firstWin and ("решаем, " .. G2.depth[G2.firstWin]) or "нерешаем"))
        SV.freeGraph(G2)
      end
    end
  end
  SV.freeGraph(G)
  end end
end
