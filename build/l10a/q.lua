-- build/l10a/q.lua файл.lua [frames] [abl] [census] [pocket=N] — быстрый прогон кандидата кв. 10 (автор, 02.10.2026; копия build/l9a/q.lua).
-- Печатает метрики ворот (как build/l6b/check.lua): ходы, состояния, скрытые/видимые по общей линейке tools/vislib.lua,
-- умная обезьяна, ДВЕРИ с пути по шагам, классы дверей (переход конфигурации деталей, стойкость — минимум ходов до
-- видимого, хвост), события/прогулка, число выигрышных конфигураций. frames — кадры кратчайшего пути (только терминал);
-- abl — абляции и контроли с фильтрами; census — перепись состояний по конфигурациям деталей.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local ST = require("solver.strict")
local V = require("tools.vislib")
local opts = {}
for i = 2, #arg do local k, v = arg[i]:match("^(%w+)=(.+)$"); if k then opts[k] = v else opts[arg[i]] = true end end
if opts.pocket then V.POCKET = tonumber(opts.pocket) end
local def = dofile(arg[1])
local lvl = R.compile(def)
local errs, warns = R.validate(lvl)
if #errs > 0 then print("ОШИБКИ: " .. table.concat(errs, "; ")) return end
for _, w in ipairs(warns) do print("warning: " .. w) end
local t0 = os.clock()
local G = SV.explore(lvl, tonumber(opts.cap) or 3000000)
if not G then print("CAP") return end
if not G.firstWin then print(string.format("НЕРЕШАЕМ (состояний %d, %.0f с)", G.n, os.clock() - t0)) return end
local good = SV.goodSet(G)
local VL = V.compute(lvl, G, def, good)
local ES, E, flag, n = G.eStart.p, G.edges.p, G.flag, G.n
local live, vis, hid, washed, nwin = 0, 0, 0, 0, 0
local hidden, wins = {}, {}
local function cfgOf(st)
  local t = {}
  for q, p in ipairs(lvl.pieces) do if p.movable then
    if st.pos[q] == 0 then t[#t+1] = (p.tag or p.what) .. "=смыт" else
    local x, y = R.xy(lvl, st.pos[q]); t[#t+1] = string.format("%s(%d,%d)%s", p.tag or p.what, x, y, st.fixed[q] and "F" or "") end end end
  return table.concat(t, " ")
end
for i = 1, n do
  if flag[i] == 1 then nwin = nwin + 1; local st = R.decode(lvl, G.keys[i]); local k = cfgOf(st) .. " L:" .. table.concat(st.body, ","); wins[k] = true end
  if flag[i] == 2 then washed = washed + 1 else
    if good[i] == 1 then live = live + 1 elseif VL.newbie[i] then vis = vis + 1 else hid = hid + 1; hidden[i] = true end
  end
end
local nwcfg = 0
local wcfg = {}
for k in pairs(wins) do local c = k:match("^(.-) L:"); wcfg[c] = true end
for _ in pairs(wcfg) do nwcfg = nwcfg + 1 end
local m = V.measure(G, good, VL.newbie)
local ex = V.measure(G, good, VL.expert)
local opt = m.opt
local path = m.path
-- расстояние до победы (для «кратчайших» состояний)
local cnt = {}
for i = 1, n + 1 do cnt[i] = 0 end
for i = 1, n do for e = ES[i-1], ES[i]-1 do cnt[E[e]] = cnt[E[e]] + 1 end end
local stt, s = {}, 1
for i = 1, n do stt[i] = s; s = s + cnt[i] end
stt[n+1] = s
local fill, rv = {}, {}
for i = 1, n do fill[i] = stt[i] end
for i = 1, n do for e = ES[i-1], ES[i]-1 do local j = E[e]; rv[fill[j]] = i; fill[j] = fill[j] + 1 end end
local dw, q, h = {}, {}, 1
for i = 1, n do if flag[i] == 1 then dw[i] = 0; q[#q+1] = i end end
while h <= #q do local j = q[h]; h = h + 1; for k = stt[j], stt[j+1]-1 do local i = rv[k]; if dw[i] == nil then dw[i] = dw[j] + 1; q[#q+1] = i end end end
-- двери с кратчайшего пути (как check.lua) и со всех кратчайших состояний (классы)
local doorsAt, doorsAll, halves = {}, 0, { 0, 0 }
for i = 1, n do if good[i] == 1 then for e = ES[i-1], ES[i]-1 do if hidden[E[e]] then doorsAll = doorsAll + 1 end end end end
for k = 1, #path - 1 do
  local sidx, c = path[k], 0
  for e = ES[sidx-1], ES[sidx]-1 do if hidden[E[e]] then c = c + 1 end end
  if c > 0 then doorsAt[#doorsAt+1] = (k-1) .. ":" .. c; local half = (k-1) < (#path-1)/2 and 1 or 2; halves[half] = halves[half] + 1 end
end
-- классы дверей со всех кратчайших состояний: переход конфигурации, фаза, стойкость (мин. ходов до видимого), хвост, размер
local agg = {}
for i = 1, n do if good[i] == 1 and flag[i] == 0 and dw[i] and G.depth[i] + dw[i] == opt then
  for e = ES[i-1], ES[i]-1 do local j = E[e]
    if hidden[j] then
      local d, qq, hh, visD, maxd = { [j] = 0 }, { j }, 1, nil, 0
      while hh <= #qq do local u = qq[hh]; hh = hh + 1
        for ee = ES[u-1], ES[u]-1 do local v = E[ee]
          if flag[v] == 0 and good[v] ~= 1 and VL.newbie[v] and (not visD or d[u] + 1 < visD) then visD = d[u] + 1 end
          if hidden[v] and d[v] == nil then d[v] = d[u] + 1; if d[v] > maxd then maxd = d[v] end; qq[#qq+1] = v end end end
      local si, sj = R.decode(lvl, G.keys[i]), R.decode(lvl, G.keys[j])
      local k = cfgOf(si) .. " → " .. cfgOf(sj)
      local a = agg[k] or { n = 0, ph = 99, phmax = 0, vis = 99, tail = 0, size = 0, ex = 0 }; agg[k] = a
      a.n = a.n + 1; a.ph = math.min(a.ph, G.depth[i]); a.phmax = math.max(a.phmax, G.depth[i])
      a.vis = math.min(a.vis, visD or 99); a.tail = math.max(a.tail, maxd); a.size = math.max(a.size, #qq)
      if not VL.expert[j] then a.ex = a.ex + 1 end
    end end end end
-- события и прогулка по кратчайшему пути
local function objs(i) local st = R.decode(lvl, G.keys[i]); local t = {}; for qq = 1, #st.pos do t[#t+1] = st.pos[qq] .. (st.fixed[qq] and "f" or "") end; return table.concat(t, ",") end
local safeSeq, streak, maxStreak, events, forced, maxForced = {}, 0, 0, 0, 0, 0
for i = 1, #path - 1 do
  local sidx, safe, all = path[i], 0, 0
  for e = ES[sidx-1], ES[sidx]-1 do all = all + 1; if good[E[e]] == 1 or flag[E[e]] == 1 then safe = safe + 1 end end
  safeSeq[#safeSeq+1] = safe
  if safe <= 1 then forced = forced + 1; if forced > maxForced then maxForced = forced end else forced = 0 end
  if objs(path[i]) ~= objs(path[i+1]) then events = events + 1; streak = 0 else streak = streak + 1; if streak > maxStreak then maxStreak = streak end end
end
print(string.format("ходов %d | состояний %d (живых %d, видимых %d, скрытых %d, смыт %d) | выигрышных состояний %d, конфигураций %d | неустойчивых %d | %.0f с",
  opt, n, live, vis, hid, washed, nwin, nwcfg, G.unstable, os.clock() - t0))
print(string.format("СКРЫТЫХ %.1f %% | УМНАЯ ОБЕЗЬЯНА %.3f %% | глубина %d у пути [%s] | знаток: скрытых %.1f %%, глубина %d",
  m.hiddenPct, m.smart, m.maxDeep, m.deepList, ex.hiddenPct, ex.maxDeep))
print(string.format("событий %d, прогулка max %d, вынужденных подряд max %d; безопасных по шагам: %s", events, maxStreak, maxForced, table.concat(safeSeq, "")))
print(string.format("ДВЕРИ с пути: %s (шагов с дверями: %d в 1-й половине, %d во 2-й) | рёбер живых→скрытых всего %d",
  #doorsAt > 0 and table.concat(doorsAt, " ") or "нет", halves[1], halves[2], doorsAll))
local lst = {}
for k, a in pairs(agg) do lst[#lst+1] = { k, a } end
table.sort(lst, function(x, y) return x[2].ph < y[2].ph end)
if #lst > 0 then print("классы дверей со всех кратчайших состояний (фаза мин–макс | входов | стойкость: мин. ходов до видимого (99 = никогда) | хвост | размер | скрыто и знатоку):") end
for _, e in ipairs(lst) do local a = e[2]
  print(string.format("  ф %2d–%2d | вх %3d | стойк %2s | хвост %3d | обл %6d | знат %3d | %s", a.ph, a.phmax, a.n, a.vis == 99 and "∞" or tostring(a.vis), a.tail, a.size, a.ex, e[1])) end
if opts.strict then
  local sx = ST.check(def, 3000000)
  if sx then print(string.format("строго: наобум %.3f %% (≤1) | кратчайших %d, ширина %d (≤3)", sx.monkey, sx.shortest, sx.maxWidth)) end
end
if opts.census then
  local aggc = {}
  for i = 1, n do if flag[i] ~= 2 then
    local st = R.decode(lvl, G.keys[i]); local k = cfgOf(st)
    local a = aggc[k] or { 0, 0, 0 }; aggc[k] = a
    if good[i] == 1 then a[1] = a[1] + 1 elseif VL.newbie[i] then a[3] = a[3] + 1 else a[2] = a[2] + 1 end end end
  local l = {}
  for k, a in pairs(aggc) do l[#l+1] = { k, a } end
  table.sort(l, function(x, y) return x[2][1] + x[2][2] > y[2][1] + y[2][2] end)
  print("перепись: конфигурация деталей | живых | скрытых | видимых")
  for i = 1, math.min(tonumber(opts.census) or 30, #l) do local a = l[i][2]; print(string.format("  %-55s %6d %7d %7d", l[i][1], a[1], a[2], a[3])) end
end
if opts.frames then
  local SYM = { source = "S", fixture = "F", stub = "T", pipe = "=", fitting = "b", porcelain = "P" }
  local function show(st, label)
    local rows = {}
    for y = 1, lvl.H do rows[y] = {} for x = 1, lvl.W do local c = lvl.cell[(y-1)*lvl.W+x]; rows[y][x] = c == 1 and "#" or (c == 2 and "~" or ".") end end
    if not st.dead then
      for _, j in ipairs(R.jets(lvl, st)) do for _, c in ipairs(j.cells) do local x, y = R.xy(lvl, c); rows[y][x] = (j.dir == R.UP) and "^" or ((j.dir == R.DOWN) and "v" or ((j.dir == R.RIGHT) and ">" or "<")) end end
    end
    for qq, pp in ipairs(lvl.pieces) do if st.pos[qq] ~= 0 then local x, y = R.xy(lvl, st.pos[qq]); local ch = pp.movable and (pp.tag or "b"):sub(1,1) or SYM[pp.kind]; if pp.movable then ch = st.fixed[qq] and ch:upper() or ch:lower() end; rows[y][x] = ch end end
    if not st.dead then for i, c in ipairs(st.body) do local x, y = R.xy(lvl, c); rows[y][x] = (i == #st.body) and "H" or ((i == 1) and "f" or "o") end end
    local out = { label }
    for y = 1, lvl.H do out[#out+1] = table.concat(rows[y]) end
    return out
  end
  local frames = {}
  for i, id in ipairs(path) do
    local st = R.decode(lvl, G.keys[id])
    local lab = (i == 1) and "start" or ((i-1) .. R.moveName(G.pmove[id]):gsub("heel", "f"):gsub("head", "H"):gsub(":", ""):sub(1, 3))
    frames[#frames+1] = show(st, lab .. (good[id] == 1 and "" or "!"))
  end
  local per = math.max(1, math.floor(120 / (lvl.W + 2)))
  for k = 1, #frames, per do
    for line = 1, #frames[k] do
      local parts = {}
      for j = k, math.min(k + per - 1, #frames) do parts[#parts+1] = string.format("%-" .. (lvl.W + 2) .. "s", frames[j][line] or "") end
      print(table.concat(parts, ""))
    end
    print()
  end
end
SV.freeGraph(G); require("ffi").C.free(good)
if opts.abl then
  local function run(ab, kind)
    local d2 = SV.deepcopy(def); d2.ablations = nil; d2.controls = nil
    SV.applyAblation(d2, ab)
    local ok, lvl2 = pcall(R.compile, d2)
    if not ok or #R.validate(lvl2) > 0 then print(string.format("%s «%s»: не компилируется → нерешаем", kind, ab.name)) return end
    local G2 = SV.explore(lvl2, 3000000, ab.filter)
    if not G2 then print(string.format("%s «%s»: CAP", kind, ab.name)) return end
    print(string.format("%s «%s»: %s | состояний %d%s", kind, ab.name, G2.firstWin and "РЕШАЕМ" or "нерешаем", G2.n,
      G2.firstWin and (" | ходов " .. G2.depth[G2.firstWin]) or ""))
    SV.freeGraph(G2)
  end
  for _, ab in ipairs(def.ablations or {}) do run(ab, "абляция") end
  for _, ab in ipairs(def.controls or {}) do run(ab, "контроль") end
end
