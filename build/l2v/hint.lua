-- build/l2v/hint.lua — ошибка подсказки №1 «не тем концом»: входы в карман, ноги ли ниже головы, через сколько ходов
-- ноги добираются до клетки захвата нижнего крюка (момент, когда «не берёт» становится видно). Только метрики.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1]); local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000); local good = SV.goodSet(G)
local W = lvl.W
local low; for q, p in ipairs(lvl.pieces) do if p.tag == "hook" and (not low or p.y > lvl.pieces[low].y) then low = q end end
local lp = lvl.pieces[low]
local grip = R.idx(lvl, lp.x + 1, lp.y) -- порт справа
local function y(c) return math.floor((c - 1) / W) + 1 end
local function isDead(i) return G.flag[i] ~= 2 and good[i] ~= 1 end
for i = 1, G.n do if good[i] == 1 then for e = G.eStart.p[i-1], G.eStart.p[i]-1 do local j = G.edges.p[e]
  if isDead(j) then
    local s0, s = R.decode(lvl, G.keys[i]), R.decode(lvl, G.keys[j])
    local feetLow = y(s.body[1]) > y(s.body[#s.body])
    -- BFS до «ноги в клетке захвата нижнего крюка» и до «голова там»
    local d, q, h, dFeet, dHead = { [j] = 0 }, { j }, 1, nil, nil
    while h <= #q do local u = q[h]; h = h + 1
      local su = R.decode(lvl, G.keys[u])
      if su.body[1] == grip and not dFeet then dFeet = d[u] end
      if su.body[#su.body] == grip and not dHead then dHead = d[u] end
      for e2 = G.eStart.p[u-1], G.eStart.p[u]-1 do local v = G.edges.p[e2]; if isDead(v) and not d[v] then d[v] = d[u] + 1; q[#q+1] = v end end end
    print(string.format("вход с глубины пути %d: ноги ниже головы=%s; ноги у нижнего крюка через %s, голова через %s; карман %d сост.",
      G.depth[i], tostring(feetLow), tostring(dFeet), tostring(dHead), #q))
  end end end end
-- через сколько ходов после входа в карман доступен первый ход, смывающий Лапидуса (попытка дотянуться до шахты)
local seen = {}
for i = 1, G.n do if good[i] == 1 then for e = G.eStart.p[i-1], G.eStart.p[i]-1 do local j = G.edges.p[e]
  if isDead(j) and not seen[j] then seen[j] = true
    local d, q, h, first, nd = { [j] = 0 }, { j }, 1, nil, 0
    while h <= #q do local u = q[h]; h = h + 1
      for e2 = G.eStart.p[u-1], G.eStart.p[u]-1 do local v = G.edges.p[e2]
        if G.flag[v] == 2 then nd = nd + 1; if not first then first = d[u] end
        elseif isDead(v) and not d[v] then d[v] = d[u] + 1; q[#q+1] = v end end end
    print(string.format("  из входа: первый смывающий ход доступен через %s ходов; смывающих рёбер в кармане %d", tostring(first), nd))
  end end end end
