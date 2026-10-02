-- build/l7j/scan.lua файл.lua [минХодов] [максХодов] — перебор стартовых клеток деталей и Лапидуса для ручной комнаты.
-- Печатает раскладки с одной выигрышной конфигурацией и кратчайшим в коридоре (решения не печатает).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local path = arg[1]
local lo, hi = tonumber(arg[2] or 20), tonumber(arg[3] or 40)
local base = dofile(path)
local lvl0 = R.compile(base)
local W, H = lvl0.W, lvl0.H
local function free(x, y) return lvl0.cell[R.idx(lvl0, x, y)] == 0 end
local fixedOcc = {}
for _, o in ipairs(base.objects) do if o.kind ~= "lapidus" and o.kind ~= "fitting" and o.kind ~= "porcelain" then fixedOcc[o.at[2] * 100 + o.at[1]] = true end end
local rest = {}
for y = 2, H - 1 do for x = 2, W - 1 do
  if free(x, y) and not fixedOcc[y * 100 + x] and (not free(x, y + 1) or fixedOcc[(y + 1) * 100 + x]) then rest[#rest + 1] = { x, y } end
end end
local movIdx = {}
for i, o in ipairs(base.objects) do if o.kind == "fitting" or o.kind == "porcelain" then movIdx[#movIdx + 1] = i end end
local lapIdx
for i, o in ipairs(base.objects) do if o.kind == "lapidus" then lapIdx = i end end
local results = {}
local function try(def)
  local lvl = R.compile(def)
  local errs = R.validate(lvl)
  if #errs > 0 then return end
  local G = SV.explore(lvl, 400000)
  if not G then return end
  if G.firstWin then
    local cfg, nc = {}, 0
    for i = 1, G.n do if G.flag[i] == 1 then local st = R.decode(lvl, G.keys[i]); local kk = {}; for q = 1, #lvl.pieces do kk[#kk + 1] = st.pos[q] .. (st.fixed[q] and "f" or "") end; local k = table.concat(kk, ","); if not cfg[k] then cfg[k] = true; nc = nc + 1 end end end
    local d = G.depth[G.firstWin]
    if nc == 1 and d >= lo and d <= hi then
      local good = SV.goodSet(G)
      local VL = V.compute(lvl, G, def, good)
      local m = V.measure(G, good, VL.newbie)
      local h1, h2 = 0, 0
      for k = 1, #m.path - 1 do
        local s = m.path[k]
        for e = G.eStart.p[s - 1], G.eStart.p[s] - 1 do if m.hidden[G.edges.p[e]] then if (k - 1) < (#m.path - 1) / 2 then h1 = h1 + 1 else h2 = h2 + 1 end break end end
      end
      require("ffi").C.free(good)
      local hookPush = 0
      for k = 1, #m.path - 1 do
        local a, b = R.decode(lvl, G.keys[m.path[k]]), R.decode(lvl, G.keys[m.path[k + 1]])
        local piece = R.occupancy(a)
        local hk = false
        for _, w in ipairs({ "head", "heel" }) do local q = R.endScrew(lvl, a, piece, w); if q and lvl.pieces[q].movable then hk = true end end
        local moved = false
        for q = 1, #lvl.pieces do if lvl.pieces[q].movable and a.pos[q] ~= b.pos[q] and not a.fixed[q] then moved = true end end
        if hk and moved then hookPush = hookPush + 1 end
      end
      local t = {}
      for _, i in ipairs(movIdx) do t[#t + 1] = def.objects[i].tag .. "(" .. def.objects[i].at[1] .. "," .. def.objects[i].at[2] .. ")" end
      local c = def.objects[lapIdx].cells
      t[#t + 1] = "L(" .. c[1][1] .. "," .. c[1][2] .. ")-(" .. c[#c][1] .. "," .. c[#c][2] .. ")h" .. def.objects[lapIdx].head
      results[#results + 1] = { d = d, n = G.n, s = table.concat(t, " "), m = string.format("скр %2.0f%% обез %.2f глуб %2d двери %d/%d крюк %d", m.hiddenPct, m.smart, m.maxDeep, h1, h2, hookPush), score = (m.maxDeep >= 8 and 1 or 0) * 100 + m.hiddenPct + (h2 > 0 and 50 or 0) - (m.smart > 0.2 and 100 or 0) + hookPush * 30 }
    end
  end
  SV.freeGraph(G)
end
-- Лапидус: горизонтально длиной Lmin на опоре, голова слева или справа
local laps = {}
local Lm = base.length[1]
for y = 2, H - 1 do for x = 2, W - Lm do
  local ok, sup = true, false
  for k = 0, Lm - 1 do if not free(x + k, y) or fixedOcc[y * 100 + x + k] then ok = false end; if not free(x + k, y + 1) then sup = true end end
  if ok and sup then
    local cells = {} for k = 0, Lm - 1 do cells[#cells + 1] = { x + k, y } end
    laps[#laps + 1] = { cells = cells, head = 1 }; laps[#laps + 1] = { cells = cells, head = Lm }
  end
end end
local onlyLap = os.getenv("ONLYLAP")
local count = 0
local function rec(k, used, def)
  if k > #movIdx then
    if onlyLap then
      for _, L in ipairs(laps) do
        local clash = false
        for _, c in ipairs(L.cells) do if used[c[2] * 100 + c[1]] then clash = true end end
        if not clash then def.objects[lapIdx].cells = L.cells; def.objects[lapIdx].head = L.head; try(def); count = count + 1 end
      end
    else
      local c = def.objects[lapIdx].cells
      for _, cc in ipairs(c) do if used[cc[2] * 100 + cc[1]] then return end end
      try(def); count = count + 1
    end
    return
  end
  local o = def.objects[movIdx[k]]
  local fixedAt = os.getenv("FIX_" .. o.tag)
  if fixedAt then rec(k + 1, used, def) return end
  for _, c in ipairs(rest) do
    if not used[c[2] * 100 + c[1]] then
      used[c[2] * 100 + c[1]] = true
      o.at = { c[1], c[2] }
      rec(k + 1, used, def)
      used[c[2] * 100 + c[1]] = nil
    end
  end
end
local used = {}
for _, i in ipairs(movIdx) do local o = base.objects[i]; if os.getenv("FIX_" .. o.tag) then used[o.at[2] * 100 + o.at[1]] = true end end
rec(1, used, base)
table.sort(results, function(a, b) return a.score > b.score end)
print(string.format("вариантов %d, подходящих %d", count, #results))
for i = 1, math.min(#results, tonumber(os.getenv("TOP") or 40)) do print(results[i].d, results[i].n, results[i].m, results[i].s) end
