-- build/l5d/mut.lua база.lua seed N out — мутатор авторского скелета кв. 5 (§7: «мутатор перебирает вариации
-- авторского скелета»): переставляет 1–3 клетки стен в сетке, сдвигает детали/старт на клетку, меняет длину.
-- Отбор — восхождение по оценке ворот 30.09 (двери с кратчайшего пути в обеих половинах, стойкость, доля, прогулка,
-- обезьяна, ступенька и лишний выход обязательны). Печатает метрики и раскладки (решений нет).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local base = dofile(arg[1])
local seed, N, out = tonumber(arg[2] or 1), tonumber(arg[3] or 200), arg[4]
math.randomseed(seed)
local fo = out and io.open(out, "a") or io.stdout
local noStep
for _, a in ipairs(base.ablations or {}) do if a.filter then noStep = a.filter end end

local function evaluate(def)
  local ok, lvl = pcall(R.compile, def)
  if not ok or #R.validate(lvl) > 0 then return nil end
  local okn, G = pcall(SV.explore, lvl, 300000)
  if not okn or not G then return nil end
  if not G.firstWin then SV.freeGraph(G) return nil end
  local opt = G.depth[G.firstWin]
  if opt < 15 or opt > 40 then SV.freeGraph(G) return nil end
  local good = SV.goodSet(G)
  local VL = V.compute(lvl, G, def, good)
  local m = V.measure(G, good, VL.newbie)
  local ES, E, flag, n = G.eStart.p, G.edges.p, G.flag, G.n
  -- все кратчайшие пути: расстояние до победы
  local cnt = {}; for i = 1, n + 1 do cnt[i] = 0 end
  for i = 1, n do for e = ES[i-1], ES[i]-1 do local j = E[e]; cnt[j] = cnt[j] + 1 end end
  local st, s = {}, 1; for i = 1, n do st[i] = s; s = s + cnt[i] end; st[n+1] = s
  local fill, rv = {}, {}; for i = 1, n do fill[i] = st[i] end
  for i = 1, n do for e = ES[i-1], ES[i]-1 do local j = E[e]; rv[fill[j]] = i; fill[j] = fill[j] + 1 end end
  local dw, q, h = {}, {}, 1
  for i = 1, n do if flag[i] == 1 then dw[i] = 0; q[#q+1] = i end end
  while h <= #q do local j = q[h]; h = h + 1; for k = st[j], st[j+1]-1 do local i = rv[k]; if dw[i] == nil then dw[i] = dw[j] + 1; q[#q+1] = i end end end
  local b1, b2, n1, n2 = 0, 0, 0, 0
  local memo = {}
  local function reveal(j)
    if memo[j] then return memo[j] end
    local d, qx, hx, rev, maxd = { [j] = 0 }, { j }, 1, nil, 0
    while hx <= #qx do local u = qx[hx]; hx = hx + 1
      for ee = ES[u-1], ES[u]-1 do local v = E[ee]
        if flag[v] == 0 and good[v] ~= 1 and VL.newbie[v] and not rev then rev = d[u] + 1 end
        if m.hidden[v] and d[v] == nil then d[v] = d[u] + 1; if d[v] > maxd then maxd = d[v] end; qx[#qx+1] = v end end end
    local r = math.min(rev or 99, maxd + 1)
    memo[j] = r
    return r
  end
  for i = 1, n do if flag[i] == 0 and good[i] == 1 and dw[i] and G.depth[i] + dw[i] == opt then
    for e = ES[i-1], ES[i]-1 do local j = E[e]
      if m.hidden[j] then
        local r = reveal(j)
        if G.depth[i] < opt / 2 then n1 = n1 + 1; if r > b1 then b1 = r end else n2 = n2 + 1; if r > b2 then b2 = r end end
      end end end end
  local function objs(i) local s2 = VL.states[i]; local t = {}; for qq = 1, #s2.pos do t[#t+1] = s2.pos[qq] .. (s2.fixed[qq] and "f" or "") end; return table.concat(t, ",") end
  local streak, walk = 0, 0
  for k = 1, #m.path - 1 do if objs(m.path[k]) ~= objs(m.path[k+1]) then streak = 0 else streak = streak + 1; if streak > walk then walk = streak end end end
  SV.freeGraph(G); require("ffi").C.free(good)
  local r = { opt = opt, n = n, hid = m.hiddenPct, smart = m.smart, b1 = b1, b2 = b2, n1 = n1, n2 = n2, walk = walk }
  local sc = math.min(r.hid, 45) + 12 * math.min(math.min(b1, 7), 7) * (n1 > 0 and 1 or 0) + 12 * math.min(b2, 7) * (n2 > 0 and 1 or 0)
    - 8 * math.max(0, walk - 6) - 40 * math.max(0, r.smart - 0.2)
  r.score = sc
  return r
end
local function roles(def)
  local ok, lvl = pcall(R.compile, def)
  if not ok then return false end
  local G = SV.explore(lvl, 300000, noStep)
  local s1 = G and G.firstWin ~= nil; if G then SV.freeGraph(G) end
  if s1 ~= false then return false end
  local d2 = SV.deepcopy(def)
  for i = #d2.objects, 1, -1 do local o = d2.objects[i]; if o.tag == "plug" then table.remove(d2.objects, i) elseif o.tag == "tee" then o.ports.left = nil end end
  local ok2, lvl2 = pcall(R.compile, d2)
  if not ok2 then return true end
  local G2 = SV.explore(lvl2, 300000)
  local s2 = G2 and G2.firstWin ~= nil; if G2 then SV.freeGraph(G2) end
  return s2 == false
end
local function copyDef(d)
  local c = SV.deepcopy(d)
  c.visibleLoss = d.visibleLoss
  c.ablations = d.ablations; c.controls = d.controls
  return c
end
local function mutate(d)
  local c = copyDef(d)
  local W, H = #c.grid[1], #c.grid
  local k = math.random(1, 3)
  for _ = 1, k do
    local r = math.random()
    if r < 0.55 then
      local x, y = math.random(2, W - 1), math.random(2, H - 1)
      local occupied = false
      for _, o in ipairs(c.objects) do
        if o.at and o.at[1] == x and o.at[2] == y then occupied = true end
        if o.cells then for _, cc in ipairs(o.cells) do if cc[1] == x and cc[2] == y then occupied = true end end end
      end
      if not occupied then
        local row = c.grid[y]
        local ch = row:sub(x, x) == "#" and "." or "#"
        c.grid[y] = row:sub(1, x - 1) .. ch .. row:sub(x + 1)
      end
    elseif r < 0.70 then
      -- прыжок детали или старта в случайную пустую клетку
      local cand = {}
      for _, o in ipairs(c.objects) do if o.kind == "fitting" or o.kind == "lapidus" then cand[#cand+1] = o end end
      local o = cand[math.random(#cand)]
      local x, y = math.random(2, W - 1), math.random(2, H - 1)
      if c.grid[y]:sub(x, x) == "." then
        if o.at then o.at = { x, y } else
          local dx, dy = x - o.cells[1][1], y - o.cells[1][2]
          for i, cc in ipairs(o.cells) do o.cells[i] = { cc[1] + dx, cc[2] + dy } end
        end
      end
    elseif r < 0.85 then
      local cand = {}
      for _, o in ipairs(c.objects) do if o.kind == "fitting" or o.kind == "fixture" or o.kind == "lapidus" then cand[#cand+1] = o end end
      local o = cand[math.random(#cand)]
      local dx, dy = ({ -1, 1, 0, 0 })[math.random(4)], 0
      if dx == 0 then dy = math.random(0, 1) * 2 - 1 end
      if o.at then o.at = { o.at[1] + dx, o.at[2] + dy } else for i, cc in ipairs(o.cells) do o.cells[i] = { cc[1] + dx, cc[2] + dy } end end
    else
      c.length = ({ { 2, 4 }, { 2, 5 }, { 3, 5 }, { 2, 3 } })[math.random(4)]
    end
  end
  return c
end
local function fmt(r) return string.format("ходов %d n %d скр %.0f%% обез %.3f прогулка %d двери 1п %d(стойк %d) 2п %d(стойк %d) score %.1f",
  r.opt, r.n, r.hid, r.smart, r.walk, r.n1, r.b1, r.n2, r.b2, r.score) end
local function dump(d, r, tag)
  fo:write(tag .. " " .. fmt(r) .. string.format(" L %d-%d\n", d.length[1], d.length[2]))
  for _, row in ipairs(d.grid) do fo:write("   " .. row .. "\n") end
  for _, o in ipairs(d.objects) do
    if o.at then local t = {} for k2, v in pairs(o.ports or {}) do t[#t+1] = k2 .. "=" .. v end
      fo:write(string.format("   %s %s (%d,%d) %s\n", o.kind, o.what or "", o.at[1], o.at[2], table.concat(t, ",")))
    else local t = {} for _, cc in ipairs(o.cells) do t[#t+1] = "{" .. cc[1] .. "," .. cc[2] .. "}" end fo:write("   lapidus " .. table.concat(t, " ") .. " head=" .. o.head .. "\n") end
  end
  fo:flush()
end
local cur = copyDef(base)
local cr = evaluate(cur)
assert(cr, "база не проходит отбор")
dump(cur, cr, "BASE")
local best = cr.score
for it = 1, N do
  local c = mutate(cur)
  local r = evaluate(c)
  if r and r.score >= cr.score - 3 * math.random() and roles(c) then
    cur, cr = c, r
    if r.score > best then best = r.score; dump(c, r, "BEST it " .. it) end
  end
end
fo:write("done " .. seed .. "\n")
