-- build/l7v_c/census.lua [file] — перепись состояний: живые / видимые (по какому правилу) / скрытые, по конфигурациям деталей.
-- Печатает классы скрытых тупиков (конфигурации деталей общими словами) и массу первого входа умной обезьяны.
local M = dofile("build/l7v_c/lib.lua")
local R = M.R
local def, lvl = M.load(arg[1])
local G, good = M.graph(def, lvl)
local VL = M.V.compute(lvl, G, def, good)
local n = G.n
-- какое правило файла сработало: перепроверяем по частям (копия логики c7.lua, только метки)
local function find()
  local t = {}
  for q, p in ipairs(lvl.pieces) do if p.source then t.src = q elseif p.fixture then t.fix = q end; if p.tag then t[p.tag] = q end end
  return t
end
local k = find()
local sx = R.xy(lvl, lvl.pieces[k.src].start)
local fixC = lvl.pieces[k.fix].start
local function ruleLabel(st)
  local tq, pq = k.tee, k.plug
  local tc, pc = st.pos[tq], st.pos[pq]
  local teeAtSink = false
  if st.fixed[tq] and tc ~= 0 then for d = 1, 4 do if lvl.nb[tc][d] == fixC then teeAtSink = true end end end
  if st.fixed[tq] and not teeAtSink then return "D тройник прикручен не у мойки" end
  if teeAtSink and not (pc == lvl.nb[tc][1] and st.fixed[pq]) then return "E тройник у мойки без заглушки" end
  local w = R.water(lvl, st, nil, true)
  local jetUp = false
  for _, L in ipairs(w.leaks) do if L.dir == 1 and (R.xy(lvl, L.cell)) == sx then jetUp = true end end
  if not jetUp and not teeAtSink then return "B фонтана больше нет" end
  if def.visibleLoss(lvl, st) then return "A деталь не попадёт в столб" end
  return nil
end
local classes = { live = {}, vis = {}, hid = {} }
local ruleCount = {}
local hidCfg, liveCfg, visCfg = {}, {}, {}
local sts = {}
for i = 1, n do
  if G.flag[i] ~= 2 then
    local st = R.decode(lvl, G.keys[i]); sts[i] = st
    local c = M.cfg(lvl, st)
    if good[i] == 1 then liveCfg[c] = (liveCfg[c] or 0) + 1
    elseif VL.newbie[i] then
      visCfg[c] = (visCfg[c] or 0) + 1
      local lab = ruleLabel(st) or "frozen (общая линейка)"
      ruleCount[lab] = (ruleCount[lab] or 0) + 1
    else hidCfg[c] = (hidCfg[c] or 0) + 1 end
  end
end
local function top(tbl, lim, title)
  local l = {}
  local total = 0
  for c, v in pairs(tbl) do l[#l + 1] = { c, v }; total = total + v end
  table.sort(l, function(a, b) return a[2] > b[2] end)
  print(string.format("%s: конфигураций %d, состояний %d", title, #l, total))
  for i = 1, math.min(lim, #l) do print(string.format("  %6d  %s", l[i][2], l[i][1])) end
end
print("Видимые по правилам файла (сколько состояний каким правилом):")
for lab, v in pairs(ruleCount) do print(string.format("  %6d  %s", v, lab)) end
top(liveCfg, 40, "ЖИВЫЕ")
top(hidCfg, 60, "СКРЫТЫЕ (по файлу)")
top(visCfg, 25, "ВИДИМЫЕ (по файлу)")
-- масса первого входа умной обезьяны в скрытые тупики, по конфигурациям (как fate.lua), и знаток
local opt = G.depth[G.firstWin]
local T = 5 * opt
local p, ok = { [1] = 1.0 }, 0
local firstDead = {}
local ES, E, flag = G.eStart.p, G.edges.p, G.flag
for step = 1, T do
  local np = {}
  for i, pr in pairs(p) do
    local cand = {}
    for e = ES[i - 1], ES[i] - 1 do local j = E[e]; if flag[j] == 1 then cand[#cand + 1] = j elseif flag[j] ~= 2 and not VL.newbie[j] then cand[#cand + 1] = j end end
    if #cand == 0 then np[i] = (np[i] or 0) + pr else
      local share = pr / #cand
      for _, j in ipairs(cand) do
        if flag[j] == 1 then ok = ok + share
        else
          if good[j] ~= 1 and good[i] == 1 then local kk = M.cfg(lvl, sts[i]) .. "  →  " .. M.cfg(lvl, sts[j]); firstDead[kk] = (firstDead[kk] or 0) + share end
          np[j] = (np[j] or 0) + share
        end
      end
    end
  end
  p = np
end
local l = {}
for kk, v in pairs(firstDead) do l[#l + 1] = { kk, v } end
table.sort(l, function(a, b) return a[2] > b[2] end)
print("Первый шаг умной обезьяны в скрытый тупик (доля массы):")
for i = 1, math.min(15, #l) do print(string.format("  %5.1f %%  %s", 100 * l[i][2], l[i][1])) end
-- знаток: сколько скрытых по файлу становятся видимыми
local exOnly = 0
for i = 1, n do if flag[i] ~= 2 and good[i] ~= 1 and not VL.newbie[i] and VL.expert[i] then exOnly = exOnly + 1 end end
print(string.format("Знаток (общая линейка) добавляет к видимым: %d состояний из скрытых по файлу", exOnly))
