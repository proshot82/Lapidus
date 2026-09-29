-- build/l7f/batch.lua [-q] файл… — сводка по кандидатам: ворота коротко + входы живое→скрытое по фазам пути
-- (с любого кратчайшего пути: фаза = глубина; печатается «глубина входа:хвост» для входов с хвостом ≥ 8).
-- -q: без строгих ворот и абляций (быстро). Кадров и ходов не печатает.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local ST = require("solver.strict")
local V = require("tools.vislib")
local quick = false
local files = {}
for _, a in ipairs(arg) do if a == "-q" then quick = true else files[#files+1] = a end end
local function cfg(lvl, s)
  local t = {}
  for q, p in ipairs(lvl.pieces) do if p.movable then
    if s.pos[q] == 0 then t[#t+1] = p.tag .. "=смыт" else
    local x, y = R.xy(lvl, s.pos[q]); t[#t+1] = string.format("%s(%d,%d)%s", p.tag, x, y, s.fixed[q] and "F" or "") end end end
  return table.concat(t, " ")
end
for _, f in ipairs(files) do
  local ok, def = pcall(dofile, f)
  local name = f:match("([^/]+)%.lua$")
  if not ok then print(name, "ошибка", def) else
  local lvl = R.compile(def)
  local errs = R.validate(lvl)
  if #errs > 0 then print(name, "ОШИБКИ", table.concat(errs, "; ")) else
  local G = SV.explore(lvl, 3000000)
  if not G or not G.firstWin then print(string.format("%-6s НЕРЕШАЕМ (%d)", name, G and G.n or -1)) else
    local good = SV.goodSet(G)
    local VL = V.compute(lvl, G, def, good)
    local m = V.measure(G, good, VL.newbie)
    local ex = V.measure(G, good, VL.expert)
    local nwin = 0; for i = 1, G.n do if G.flag[i] == 1 then nwin = nwin + 1 end end
    local ES, E, flag = G.eStart.p, G.edges.p, G.flag
    local n = G.n
    -- расстояние до победы
    local cnt = {}
    for i = 1, n + 1 do cnt[i] = 0 end
    for i = 1, n do for e = ES[i-1], ES[i]-1 do local j = E[e]; cnt[j] = cnt[j] + 1 end end
    local st, s = {}, 1
    for i = 1, n do st[i] = s; s = s + cnt[i] end
    st[n+1] = s
    local fill, rv = {}, {}
    for i = 1, n do fill[i] = st[i] end
    for i = 1, n do for e = ES[i-1], ES[i]-1 do local j = E[e]; rv[fill[j]] = i; fill[j] = fill[j] + 1 end end
    local dw, q, h = {}, {}, 1
    for i = 1, n do if flag[i] == 1 then dw[i] = 0; q[#q+1] = i end end
    while h <= #q do local j = q[h]; h = h + 1; for k = st[j], st[j+1]-1 do local i = rv[k]; if dw[i] == nil then dw[i] = dw[j] + 1; q[#q+1] = i end end end
    local function depthFrom(j, hid)
      local d, qq, hh, maxd = { [j] = 0 }, { j }, 1, 0
      while hh <= #qq do local u = qq[hh]; hh = hh + 1
        for e = ES[u-1], ES[u]-1 do local v = E[e]
          if hid[v] and d[v] == nil then d[v] = d[u]+1; if d[v] > maxd then maxd = d[v] end; qq[#qq+1] = v end end end
      return maxd, #qq
    end
    -- входы с кратчайших путей по фазам (новичок), сгруппированы по конфигурации-переходу
    local agg, aggE = {}, {}
    local doorsN, doorsE = 0, 0
    for i = 1, n do if good[i] == 1 and flag[i] == 0 then
      local onpath = (dw[i] and G.depth[i] + dw[i] == m.opt)
      for e = ES[i-1], ES[i]-1 do local j = E[e]
        if m.hidden[j] then
          doorsN = doorsN + 1
          if not VL.expert[j] then doorsE = doorsE + 1 end
          if onpath then
            local k = cfg(lvl, VL.states[i]) .. "→" .. cfg(lvl, VL.states[j])
            local a = agg[k] or { minD = 999, tail = 0, sz = 0, ex = false }; agg[k] = a
            if G.depth[i] < a.minD then a.minD = G.depth[i] end
            local t, sz = depthFrom(j, m.hidden); if t > a.tail then a.tail = t; a.sz = sz end
            if not VL.expert[j] then a.ex = true end
          end
        end end end end
    local ds = {}
    for k, a in pairs(agg) do if a.tail >= 8 then ds[#ds+1] = { a.minD, string.format("%d:%d%s", a.minD, a.tail, a.ex and "" or "з") } end end
    table.sort(ds, function(x, y) return x[1] < y[1] end)
    local dl = {}; for _, d in ipairs(ds) do dl[#dl+1] = d[2] end
    local extra = ""
    if not quick then
      local sx = ST.check(def, 3000000)
      local abl = SV.ablations(def, { cap = 3000000 })
      local bad = {}
      for _, a in ipairs(abl) do if a.solvable ~= false then bad[#bad+1] = a.name end end
      extra = string.format(" | наобум %.3f крат %d/шир %d%s", sx and sx.monkey or -1, sx and sx.shortest or -1, sx and sx.maxWidth or -1,
        #bad > 0 and (" АБЛ.РЕШАЕМЫ: " .. table.concat(bad, "; ")) or "")
    end
    local path, x = {}, G.firstWin
    while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
    table.insert(path, 1, 1)
    local function objs(i) local s2 = R.decode(lvl, G.keys[i]); local t = {}; for qq = 1, #s2.pos do t[#t+1] = s2.pos[qq] .. (s2.fixed[qq] and "f" or "") end; return table.concat(t, ",") end
    local streak, maxStreak, events, safe = 0, 0, 0, {}
    for i = 1, #path - 1 do
      local sf = 0; for e = ES[path[i]-1], ES[path[i]]-1 do if good[E[e]] == 1 then sf = sf + 1 end end; safe[#safe+1] = sf
      if objs(path[i]) ~= objs(path[i+1]) then events = events + 1; streak = 0 else streak = streak + 1; if streak > maxStreak then maxStreak = streak end end
    end
    local forced, mf = 0, 0
    for _, sf in ipairs(safe) do if sf <= 1 then forced = forced + 1; if forced > mf then mf = forced end else forced = 0 end end
    print(string.format("%-6s ход %2d сост %6d жив %5d выигр %d СКР %4.1f%% (зн %4.1f%%) обез %.2f глуб %2d [%s] соб %d прог %d вын %d ст.ходов %d | дверей %d (зн %d) | входы с пути ≥8: %s%s",
      name, m.opt, G.n, m.live, nwin, m.hiddenPct, ex.hiddenPct, m.smart, m.maxDeep, m.deepList, events, maxStreak, mf, safe[1] or 0, doorsN, doorsE, table.concat(dl, " "), extra))
    SV.freeGraph(G); require("ffi").C.free(good)
  end end end
end
