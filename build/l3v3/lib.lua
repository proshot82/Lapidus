-- build/l3v3/lib.lua — заготовки слепого скептика кв. 3 (s8), 01.10.2026. Ничего не печатает про порядок ходов.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local L = { R = R, SV = SV, V = V }

function L.load(path, pocket, filter)
  local def = type(path) == "table" and path or dofile(path or "levels/03.lua")
  local lvl = R.compile(def)
  local G = SV.explore(lvl, 3000000, filter)
  assert(G, "cap")
  local good = SV.goodSet(G)
  V.POCKET = pocket or 4
  local VL = G.firstWin and V.compute(lvl, G, def, good) or nil
  V.POCKET = 4
  local sts = {}
  for i = 1, G.n do if G.flag[i] ~= 2 then sts[i] = R.decode(lvl, G.keys[i]) end end
  local ctx = { def = def, lvl = lvl, G = G, good = good, VL = VL, sts = sts }
  ctx.soaps = {}
  for q, p in ipairs(lvl.pieces) do if p.porcelain then ctx.soaps[#ctx.soaps + 1] = q end end
  ctx.step = (7 - 1) * lvl.W + 7
  return ctx
end

function L.xy(ctx, c) return R.xy(ctx.lvl, c) end
function L.edges(ctx, i)
  local G, out = ctx.G, {}
  for e = G.eStart.p[i - 1], G.eStart.p[i] - 1 do out[#out + 1] = G.edges.p[e] end
  return out
end
function L.status(ctx, i)
  local G = ctx.G
  if G.flag[i] == 2 then return "wash" end
  if G.flag[i] == 1 then return "win" end
  if ctx.good[i] == 1 then return "live" end
  if ctx.VL.newbie[i] then return "vis" end
  return "hid"
end
function L.below(ctx, st, c)
  local lvl = ctx.lvl
  local b = lvl.nb[c][3]
  if b == 0 or lvl.cell[b] == 1 then return "wall" end
  if lvl.cell[b] == 2 then return "pit" end
  for k, c2 in ipairs(st.body) do if c2 == b then return (k == 1 and "heel" or (k == #st.body and "head" or "body")) end end
  for _, q in ipairs(ctx.soaps) do if st.pos[q] == b then return "soap" end end
  return "empty"
end
-- конфигурация мыла: "верх(x,y)/под низ(x,y)/под"
function L.cfg(ctx, st, noUnder)
  local t = {}
  for _, q in ipairs(ctx.soaps) do
    local c = st.pos[q]
    if c == 0 then t[#t + 1] = "смыто" else
      local x, y = R.xy(ctx.lvl, c)
      t[#t + 1] = string.format("(%d,%d)%s", x, y, noUnder and "" or ("/" .. L.below(ctx, st, c)))
    end
  end
  return table.concat(t, " ")
end
-- обратные рёбра и расстояние до победы (по всем состояниям, кроме смытых)
function L.distToWin(ctx)
  if ctx.dist then return ctx.dist end
  local G = ctx.G
  local rev = {}
  for i = 1, G.n do if G.flag[i] ~= 2 then for _, j in ipairs(L.edges(ctx, i)) do rev[j] = rev[j] or {}; table.insert(rev[j], i) end end end
  local dist = {}
  local q, h = {}, 1
  for i = 1, G.n do if G.flag[i] == 1 then dist[i] = 0; q[#q + 1] = i end end
  while h <= #q do
    local u = q[h]; h = h + 1
    for _, p in ipairs(rev[u] or {}) do if dist[p] == nil then dist[p] = dist[u] + 1; q[#q + 1] = p end end
  end
  ctx.dist, ctx.rev = dist, rev
  return dist
end
-- состояния на кратчайших путях: depth + dist == opt
function L.onShortest(ctx)
  local G = ctx.G
  local dist = L.distToWin(ctx)
  local opt = G.depth[G.firstWin]
  local on = {}
  for i = 1, G.n do if G.flag[i] ~= 2 and dist[i] and G.depth[i] + dist[i] == opt then on[i] = true end end
  return on, opt
end
-- все кратчайшие пути как списки id
function L.allShortest(ctx)
  local G = ctx.G
  local on, opt = L.onShortest(ctx)
  local paths = {}
  local function dfs(u, acc)
    if G.flag[u] == 1 then local c = {}; for k, v in ipairs(acc) do c[k] = v end; paths[#paths + 1] = c; return end
    for _, v in ipairs(L.edges(ctx, u)) do
      if on[v] and G.depth[v] == G.depth[u] + 1 then acc[#acc + 1] = v; dfs(v, acc); acc[#acc] = nil end
    end
  end
  dfs(1, { 1 })
  return paths, opt
end
function L.free(ctx) SV.freeGraph(ctx.G); require("ffi").C.free(ctx.good) end
-- копия уровня с замурованными клетками
function L.brick(def, cells)
  local d = SV.deepcopy(def)
  d.ablations = nil
  for _, c in ipairs(cells) do
    local x, y = c[1], c[2]
    assert(d.grid[y]:sub(x, x) == ".", "не пусто " .. x .. "," .. y)
    d.grid[y] = d.grid[y]:sub(1, x - 1) .. "#" .. d.grid[y]:sub(x + 1)
  end
  return d
end
-- краткие метрики варианта (решаем, ходов, состояний, скрытых %, глубина, двери по половинам)
function L.metrics(def, filter, pocket)
  local ok, ctx = pcall(L.load, def, pocket, filter)
  if not ok then return { err = tostring(ctx) } end
  local G = ctx.G
  if not G.firstWin then local n = G.n; L.free(ctx); return { solvable = false, n = n } end
  local m = V.measure(G, ctx.good, ctx.VL.newbie)
  local live, hid, vis, nwin = 0, 0, 0, 0
  for i = 1, G.n do
    local s = L.status(ctx, i)
    if s == "live" then live = live + 1 elseif s == "hid" then hid = hid + 1 elseif s == "vis" then vis = vis + 1 elseif s == "win" then nwin = nwin + 1 end
  end
  -- двери с кратчайших путей (всех) по половинам
  local on, opt = L.onShortest(ctx)
  local d1, d2, dn = 0, 0, 0
  for i in pairs(on) do
    if G.flag[i] == 0 then
      local c = 0
      for _, j in ipairs(L.edges(ctx, i)) do if L.status(ctx, j) == "hid" then c = c + 1 end end
      if c > 0 then dn = dn + c; if G.depth[i] < opt / 2 then d1 = d1 + 1 else d2 = d2 + 1 end end
    end
  end
  local r = { solvable = true, n = G.n, opt = opt, live = live, hid = hid, vis = vis, nwin = nwin, hidPct = m.hiddenPct,
    smart = m.smart, deep = m.maxDeep, dl = m.deepList, doors = dn, doors1 = d1, doors2 = d2 }
  L.free(ctx)
  return r
end
function L.fmt(r)
  if r.err then return "ОШИБКА " .. r.err end
  if not r.solvable then return string.format("НЕРЕШАЕМ (состояний %d)", r.n) end
  return string.format("ходов %d, сост. %d (живых %d, скрытых %d, видимых %d, побед %d) | скрытых %.1f %% | обезьяна %.2f | глубина %d [%s] | дверей с кратчайших %d (сост. 1-й пол. %d, 2-й пол. %d)",
    r.opt, r.n, r.live, r.hid, r.vis, r.nwin, r.hidPct, r.smart, r.deep, r.dl, r.doors, r.doors1, r.doors2)
end
return L
