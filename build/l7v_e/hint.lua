-- build/l7v_e/hint.lua файл.lua — состояния «приём подсказки №1 применён» (деталь в столбе фонтана, прямо над ней тело;
-- «пробка у основания» — деталь в первой клетке столба): живые / скрытые / видимые, первая досягаемость и глубина скрытого хвоста.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local VL = V.compute(lvl, G, def, good)
local m = V.measure(G, good, VL.newbie)
local Q = {}; for q, p in ipairs(lvl.pieces) do if p.tag then Q[p.tag] = q end end
local tee; for q, p in ipairs(lvl.pieces) do if p.what == "tee" then tee = q end end
local base = lvl.nb[lvl.pieces[tee].start][1]
local function fountain(ns)
  local col = {}
  for _, j in ipairs(R.jets(lvl, ns)) do if j.dir == R.UP and not j.lapidus then for _, c in ipairs(j.cells) do col[c] = true end end end
  return col
end
local function held(s)
  if s.dead then return nil end
  local col = fountain(s); local body = {}; for _, c in ipairs(s.body) do body[c] = true end
  for q, p in ipairs(lvl.pieces) do local c = s.pos[q]
    if p.movable and c ~= 0 and not s.fixed[q] and col[c] and body[lvl.nb[c][1]] then return p.tag end end
end
local function depthFrom(j)
  local d, q, h, maxd = { [j] = 0 }, { j }, 1, 0
  while h <= #q do local u = q[h]; h = h + 1
    for e = G.eStart.p[u-1], G.eStart.p[u]-1 do local v = G.edges.p[e]
      if m.hidden[v] and d[v] == nil then d[v] = d[u]+1; if d[v] > maxd then maxd = d[v] end; q[#q+1] = v end end end
  return maxd
end
local cnt = {}
local best = {}
for i = 1, G.n do if G.flag[i] ~= 2 then
  local s = VL.states[i]
  local h = held(s)
  if h then
    local k = h .. (s.pos[Q[h]] == base and "@основание" or "@выше")
    local a = cnt[k] or { 0, 0, 0, 999, 0, 0 }; cnt[k] = a
    if good[i] == 1 then a[1] = a[1] + 1 elseif VL.newbie[i] then a[3] = a[3] + 1 else a[2] = a[2] + 1
      -- первый вход в скрытый тупик: родитель живой
      local p = G.parent[i]
      if G.depth[i] < a[4] then a[4] = G.depth[i] end
      local d = depthFrom(i); if d > a[5] then a[5] = d end
    end
  end
end end
for k, a in pairs(cnt) do print(string.format("держит %-18s живых %5d скрытых %5d видимых %5d | ближайший скрытый на глубине %d от старта, хвост до %d", k, a[1], a[2], a[3], a[4], a[5])) end
-- ходы из живых состояний прямо в скрытое «держит»-состояние (ошибка применения приёма)
local entries, ent = {}, 0
for i = 1, G.n do if good[i] == 1 then
  for e = G.eStart.p[i-1], G.eStart.p[i]-1 do local j = G.edges.p[e]
    if m.hidden[j] and held(VL.states[j]) then ent = ent + 1; local d = depthFrom(j); entries[d] = (entries[d] or 0) + 1 end end end end
local t = {}; for d, c in pairs(entries) do t[#t+1] = d .. ":" .. c end; table.sort(t)
print("переходов живое→скрытое «держит»: " .. ent .. "; по глубине хвоста: " .. table.concat(t, " "))
