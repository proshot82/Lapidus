-- verify2_census.lua файл.lua — разметки видимого проигрыша (verify2_vis.lua) на одном графе:
-- живых среди помеченных (должно быть 0), скрытых %, умная обезьяна, глубина скрытой ветки у пути,
-- и перепись скрытых тупиков по классам (общими словами). Решений и кадров не печатает.
package.path = "./?.lua;" .. package.path
local L = dofile("build/l7c/b_lift_cargo/verify2_lib.lua")
local V = dofile("build/l7c/b_lift_cargo/verify2_vis.lua")
local VA = dofile("build/l7c/b_lift_cargo/vis.lua")
local R = L.R
local def = dofile(arg[1])
local lvl, G, good = L.graph(def)
local k = L.keys(lvl)
local sx = k.sx
local S = {}
for i = 1, G.n do if G.flag[i] ~= 2 then S[i] = R.decode(lvl, G.keys[i]) end end
local modes = { "mine", "wide(автор)", "base", "honest-N", "honest-Sr", "honest" }
local fn = {}
for _, m in ipairs(modes) do
  if m == "wide(автор)" then local f = VA.make("wide"); fn[m] = f else fn[m] = V.make(def, m) end
end
local path = L.path(G)
local opt = #path - 1
local function metrics(lost)
  local live, vis, hid, bad = 0, 0, 0, 0
  local hidden = {}
  for i = 1, G.n do
    if G.flag[i] == 1 then live = live + 1 -- как в check.lua: выигрышное состояние считается живым
    elseif G.flag[i] == 0 then
      if good[i] == 1 then live = live + 1; if lost[i] then bad = bad + 1 end
      elseif lost[i] then vis = vis + 1 else hid = hid + 1; hidden[i] = true end
    end
  end
  -- умная обезьяна (как в check.lua)
  local T = 5 * opt
  local p, ok = { [1] = 1.0 }, 0
  for _ = 1, T do
    local np = {}
    for i, pr in pairs(p) do
      local cand = {}
      for e = G.eStart.p[i - 1], G.eStart.p[i] - 1 do
        local j = G.edges.p[e]
        if G.flag[j] == 1 then cand[#cand + 1] = j elseif G.flag[j] ~= 2 and not lost[j] then cand[#cand + 1] = j end
      end
      if #cand == 0 then np[i] = (np[i] or 0) + pr else
        local share = pr / #cand
        for _, j in ipairs(cand) do if G.flag[j] == 1 then ok = ok + share else np[j] = (np[j] or 0) + share end end
      end
    end
    p = np
  end
  local liveP, deadP = 0, 0
  for i, pr in pairs(p) do if good[i] == 1 then liveP = liveP + pr else deadP = deadP + pr end end
  local smart = 100 * (1 - (1 - ok) ^ (1000 / T))
  -- глубина скрытой ветки у пути (как в check.lua)
  local function depthFrom(j)
    local d, q, h, maxd = { [j] = 0 }, { j }, 1, 0
    while h <= #q do
      local u = q[h]; h = h + 1
      for e = G.eStart.p[u - 1], G.eStart.p[u] - 1 do
        local v = G.edges.p[e]
        if hidden[v] and d[v] == nil then d[v] = d[u] + 1; if d[v] > maxd then maxd = d[v] end; q[#q + 1] = v end
      end
    end
    return maxd, #q
  end
  local deepAt, maxDeep = {}, 0
  for kk = 1, #path - 1 do
    local s = path[kk]
    for e = G.eStart.p[s - 1], G.eStart.p[s] - 1 do
      local j = G.edges.p[e]
      if hidden[j] then local d = depthFrom(j); if d > (deepAt[kk - 1] or -1) then deepAt[kk - 1] = d end; if d > maxDeep then maxDeep = d end end
    end
  end
  local dl = {}
  for kk = 0, #path - 2 do if deepAt[kk] then dl[#dl + 1] = kk .. ":" .. deepAt[kk] end end
  return { live = live, vis = vis, hid = hid, bad = bad, smart = smart, ok = ok, liveP = liveP, deadP = deadP,
           maxDeep = maxDeep, dl = table.concat(dl, " "), hidden = hidden }
end
local res = {}
for _, m in ipairs(modes) do
  local lost = {}
  local f = fn[m]
  for i = 1, G.n do
    if G.flag[i] == 0 then lost[i] = L.washed(lvl, S[i]) or f(lvl, S[i]) end
  end
  local r = metrics(lost)
  res[m] = r
  print(string.format("%-11s живых помечено %d | живых %d, видимых %d, скрытых %d | СКРЫТЫХ %.1f %% | обезьяна %.3f %% (за %d ходов: выигрыш %.4f %%, живы %.1f %%, в тупиках %.1f %%) | ГЛУБИНА %d у пути [%s]",
    m, r.bad, r.live, r.vis, r.hid, 100 * r.hid / math.max(1, r.hid + r.live), r.smart, 5 * opt, 100 * r.ok, 100 * r.liveP, 100 * r.deadP, r.maxDeep, r.dl))
end
-- перепись скрытых тупиков по классам (общими словами), для разметок «wide(автор)» и «honest»
local tq, pq, aq, nq = k.tee, k.plug, k.adp, k.nip
local function inCol(c) return c ~= 0 and (R.xy(lvl, c)) == sx end
local function classOf(st)
  local tc, pc, ac = st.pos[tq], st.pos[pq], st.pos[aq]
  local side = L.lapSide(lvl, st, sx)
  if st.fixed[nq] then return "ниппель в основании раньше, чем вся стопка в столбе" end
  if st.fixed[tq] then
    if L.joined(lvl, st, tq, aq) and ac == lvl.nb[tc][R.DOWN] then return "переходник прикручен под тройником у мойки" end
    if not inCol(ac) then return "тройник с заглушкой у мойки, переходник забыт в очереди" end
    return "тройник у мойки, прочее"
  end
  if L.joined(lvl, st, tq, aq) and ac == lvl.nb[tc][R.DOWN] then return "тройник свинчен сверху на переходник" end
  if L.joined(lvl, st, pq, tq) then
    if inCol(tc) then return "тройник с заглушкой в столбе, переходник забыт в очереди" end
    return "заглушка свинчена прямо на тройник (переходнику не встать между ними)"
  end
  if (R.xy(lvl, tc)) > sx then return "тройник перенесён на правую сторону" end
  if L.joined(lvl, st, pq, aq) and not inCol(pc) then
    return "заглушка с переходником на правой стороне, тройник " .. (inCol(tc) and "в столбе" or "на старте")
  end
  if side == "L" then return "Лапидус заперт слева, пока стопка ещё не собрана" end
  return "прочее"
end
for _, m in ipairs({ "wide(автор)", "honest" }) do
  local cls, ex = {}, {}
  for i in pairs(res[m].hidden) do
    local c = classOf(S[i])
    cls[c] = (cls[c] or 0) + 1
  end
  local l = {}
  for c, n in pairs(cls) do l[#l + 1] = { c, n } end
  table.sort(l, function(a, b) return a[2] > b[2] end)
  print(string.format("скрытые тупики по классам, разметка %s (всего %d):", m, res[m].hid))
  for _, e in ipairs(l) do print(string.format("  %5d  %s", e[2], e[1])) end
end
L.SV.freeGraph(G); require("ffi").C.free(good)
