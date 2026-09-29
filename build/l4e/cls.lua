-- build/l4e/cls.lua файл.lua — классы состояний по конфигурации деталей (живые / скрытые / видимые), двери живое→скрытое
-- по классам и расстояние ближайшей двери от кратчайшего пути. Решений не печатает.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local VL = V.compute(lvl, G, def, good)
local win = VL.win
local function xy(c) return R.xy(lvl, c) end
local function sig(st)
  local t = {}
  for q, p in ipairs(lvl.pieces) do
    if p.movable then
      local c = st.pos[q]
      local s
      if c == 0 then s = "смыт"
      elseif st.fixed[q] then s = (c == win.pos[q]) and "НА МЕСТЕ" or string.format("ПРИКР(%d,%d)", xy(c))
      else
        local x, y = xy(c)
        local pair = ""
        for r, pr in ipairs(lvl.pieces) do if r ~= q and pr.movable and st.pos[r] ~= 0 and not st.fixed[r] and st.asm[r] == st.asm[q] then pair = "+" .. pr.tag end end
        s = "своб.ряд" .. y .. pair
      end
      t[#t + 1] = p.tag .. ":" .. s
    end
  end
  return table.concat(t, " | ")
end
local path, x = {}, G.firstWin
while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
table.insert(path, 1, 1)
local onPath, dist, q, h = {}, {}, {}, 1
for k, s in ipairs(path) do onPath[s] = k - 1; dist[s] = 0; q[#q + 1] = s end
while h <= #q do
  local u = q[h]; h = h + 1
  if G.flag[u] ~= 2 and good[u] == 1 then
    for e = G.eStart.p[u - 1], G.eStart.p[u] - 1 do local v = G.edges.p[e]; if dist[v] == nil and good[v] == 1 then dist[v] = dist[u] + 1; q[#q + 1] = v end end
  end
end
local agg = {}
local hidden = {}
for i = 1, G.n do
  if G.flag[i] ~= 2 then
    local k = sig(VL.states[i])
    local a = agg[k] or { live = 0, hid = 0, vis = 0, doors = 0, near = 1e9, nearStep = nil }; agg[k] = a
    if good[i] == 1 then a.live = a.live + 1 elseif VL.newbie[i] then
      a.vis = a.vis + 1
      local st = VL.states[i]
      local why = {}
      for _, q in ipairs(VL.needed) do
        if st.pos[q] == 0 then why[#why + 1] = lvl.pieces[q].tag .. ":смыт"
        elseif not st.fixed[q] and st.pos[q] ~= win.pos[q] and not VL.canMove[q][i] then why[#why + 1] = lvl.pieces[q].tag .. ":замёрзла"
        elseif VL.sealedBy[q][i] then why[#why + 1] = lvl.pieces[q].tag .. ":карман" end
      end
      if #why == 0 then why[1] = "правило уровня" end
      local w = table.concat(why, ",")
      a.why = a.why or {}; a.why[w] = (a.why[w] or 0) + 1
    else a.hid = a.hid + 1; hidden[i] = true end
  end
end
local function depthFrom(j)
  local d, qq, hh, maxd = { [j] = 0 }, { j }, 1, 0
  while hh <= #qq do
    local u = qq[hh]; hh = hh + 1
    for e = G.eStart.p[u - 1], G.eStart.p[u] - 1 do
      local v = G.edges.p[e]
      if hidden[v] and d[v] == nil then d[v] = d[u] + 1; if d[v] > maxd then maxd = d[v] end; qq[#qq + 1] = v end
    end
  end
  return maxd
end
for i = 1, G.n do
  if G.flag[i] ~= 2 and good[i] == 1 then
    for e = G.eStart.p[i - 1], G.eStart.p[i] - 1 do
      local j = G.edges.p[e]
      if hidden[j] then
        local a = agg[sig(VL.states[j])]
        a.doors = a.doors + 1
        local dd = dist[i] or 1e9
        if dd < a.near then a.near = dd; a.nearStep = onPath[i]; a.depth = depthFrom(j) end
      end
    end
  end
end
local list = {}
for k, a in pairs(agg) do list[#list + 1] = { k, a } end
table.sort(list, function(a, b) return a[2].hid + a[2].live > b[2].hid + b[2].live end)
print(string.format("%-90s %6s %7s %7s %6s %s", "класс", "живых", "скрытых", "видимых", "дверей", "ближайшая дверь (от пути / шаг пути / глубина)"))
for _, e in ipairs(list) do
  local a = e[2]
  local wl = {}
  for w, n in pairs(a.why or {}) do wl[#wl + 1] = w .. "=" .. n end
  print(string.format("%-90s %6d %7d %7d %6d %s  %s", e[1], a.live, a.hid, a.vis, a.doors,
    a.doors > 0 and string.format("%d / %s / %d", a.near, tostring(a.nearStep), a.depth or 0) or "", (arg[2] == "vis") and table.concat(wl, " ") or ""))
end
SV.freeGraph(G); require("ffi").C.free(good)
