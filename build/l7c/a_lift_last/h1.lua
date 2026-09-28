-- h1.lua файл.lua — ошибки «по подсказке №1»: переходы из живых состояний в тупики по классам ошибок,
-- скрытые ли эти тупики (не помечены visibleLoss), как рано достижимы и сколько ходов по ним можно блуждать
-- до видимого проигрыша. Печатает только числа (без ходов и кадров).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local Q = {}
for q, p in ipairs(lvl.pieces) do if p.tag then Q[p.tag] = q end end
local st = {}
local function S(i) if not st[i] then st[i] = R.decode(lvl, G.keys[i]) end return st[i] end
local function lost(s)
  for q, p in ipairs(lvl.pieces) do if p.movable and s.pos[q] == 0 then return true end end
  return def.visibleLoss and def.visibleLoss(lvl, s) or false
end
local function inJet(s, c, inside)
  if c == 0 then return false end
  for _, j in ipairs(R.jets(lvl, s)) do
    if j.dir == 1 and #j.cells > 0 then
      for _, t in ipairs(j.cells) do if t == c then return true end end
      if not inside and lvl.nb[j.cells[#j.cells]][1] == c then return true end
    end
  end
  return false
end
local classes = {
  { "E1 муфту скормили фонтану раньше, чем переходник в ванне", function(a, b)
      return not inJet(a, a.pos[Q.cpl], true) and inJet(b, b.pos[Q.cpl], true) and not b.fixed[Q.adp] end },
  { "E2 переходник свинтился с муфтой (обе на фонтане/рядом)", function(a, b)
      return a.asm[Q.adp] ~= a.asm[Q.cpl] and b.asm[Q.adp] == b.asm[Q.cpl] end },
  { "E3 фонтан заглушён после переходника, но до муфты", function(a, b)
      return not a.fixed[Q.elb] and b.fixed[Q.elb] and b.fixed[Q.adp] and not inJet(a, a.pos[Q.cpl], true) end },
  { "E4 муфта вкручена (в ванну или куда-то ещё)", function(a, b)
      return not a.fixed[Q.cpl] and b.fixed[Q.cpl] end },
  { "E5 фонтан заглушён раньше переходника", function(a, b)
      return not a.fixed[Q.elb] and b.fixed[Q.elb] and not b.fixed[Q.adp] end },
}
local function wander(j)
  -- BFS по мёртвым невидимым состояниям: сколько ходов можно блуждать до видимого проигрыша
  local d, q, h, maxd = { [j] = 0 }, { j }, 1, 0
  while h <= #q do
    local u = q[h]; h = h + 1
    for e = G.eStart.p[u - 1], G.eStart.p[u] - 1 do
      local v = G.edges.p[e]
      if not d[v] and G.flag[v] ~= 2 and good[v] ~= 1 and not lost(S(v)) then
        d[v] = d[u] + 1; if d[v] > maxd then maxd = d[v] end; q[#q + 1] = v
      end
    end
  end
  return maxd
end
for _, C in ipairs(classes) do
  local fromLive, toLive, toHid, toVis, minDepth, wmax, wsum, wn = 0, 0, 0, 0, 1e9, 0, 0, 0
  local seenT = {}
  for i = 1, G.n do
    if good[i] == 1 and G.flag[i] ~= 2 then
      for e = G.eStart.p[i - 1], G.eStart.p[i] - 1 do
        local j = G.edges.p[e]
        if G.flag[j] ~= 2 and C[2](S(i), S(j)) then
          fromLive = fromLive + 1
          if good[j] == 1 then toLive = toLive + 1
          elseif lost(S(j)) then toVis = toVis + 1
          else
            toHid = toHid + 1
            if G.depth[i] < minDepth then minDepth = G.depth[i] end
            if not seenT[j] then seenT[j] = true; local w = wander(j); wn = wn + 1; wsum = wsum + w; if w > wmax then wmax = w end end
          end
        end
      end
    end
  end
  print(string.format("%s: переходов из живых %d → живые %d, скрытые тупики %d, видимые %d; раньше всего с глубины %s; блуждание до видимого: ср. %.1f, макс %d",
    C[1], fromLive, toLive, toHid, toVis, minDepth < 1e9 and tostring(minDepth) or "—", wn > 0 and wsum / wn or 0, wmax))
end
-- уровень состояний (как build/l6/claims.lua): сколько состояний каждого класса живы / мертвы скрыто / мертвы видимо
local SCL = {
  { "S1 фонтан заглушён, переходник не в ванне", function(b) return b.fixed[Q.elb] and not b.fixed[Q.adp] end },
  { "S2 муфта закреплена (вкручена)", function(b) return b.fixed[Q.cpl] end },
  { "S3 муфта внутри струи, переходник не в ванне", function(b) return inJet(b, b.pos[Q.cpl], true) and not b.fixed[Q.adp] end },
}
for _, C in ipairs(SCL) do
  local lv, hd, vs, mind = 0, 0, 0, 1e9
  for i = 1, G.n do
    if G.flag[i] ~= 2 and C[2](S(i)) then
      if good[i] == 1 then lv = lv + 1 elseif lost(S(i)) then vs = vs + 1 else hd = hd + 1; if G.depth[i] < mind then mind = G.depth[i] end end
    end
  end
  print(string.format("%s: живых %d, мёртвых скрытых %d (ближайшее на глубине %s), мёртвых видимых %d", C[1], lv, hd, mind < 1e9 and tostring(mind) or "—", vs))
end
SV.freeGraph(G)
