-- build/l7v_g/abl2.lua файл.lua — узкие абляции скептика (фильтры переходов), длина решения при каждой.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local W = lvl.W
local function fountain(ns)
  local c = {}
  for _, j in ipairs(R.jets(lvl, ns)) do if j.dir == R.UP and not j.lapidus then for _, x in ipairs(j.cells) do c[x] = true end end end
  return c
end
local function screwed(ns)
  local occ = {}
  for q = 1, #ns.pos do if ns.pos[q] ~= 0 then occ[ns.pos[q]] = q end end
  local w = R.water(lvl, ns, occ)
  return w.headQ or w.heelQ
end
-- что случилось при устаканивании: ищем ход, дающий ns, и смотрим трассу
local cache = {}
local function trace(st, ns)
  local k = R.key(ns)
  for m = 1, 8 do
    local mv = R.MOVES[m]
    local tr = {}
    local s2 = R.move(lvl, st, mv.which, mv.dir, tr)
    if s2 and R.key(s2) == k then return tr end
  end
end
local function shifted(a, b, d) -- тело b = тело a, сдвинутое на d
  if #a ~= #b then return false end
  for i = 1, #a do if b[i] ~= a[i] + d then return false end end
  return true
end
local function lapLifted(lvl_, st, ns)
  if ns.dead then return true end
  local tr = trace(st, ns); if not tr then return true end
  for i = 2, #tr do
    if tr[i].kind == "settle" and shifted(tr[i-1].state.body, tr[i].state.body, -W) then return false end
  end
  return true
end
local function pieceLifted(which)
  local q0; for q, p in ipairs(lvl.pieces) do if p.tag == which then q0 = q end end
  return function(lvl_, st, ns)
    if ns.dead then return true end
    local tr = trace(st, ns); if not tr then return true end
    for i = 2, #tr do
      local a, b = tr[i-1].state, tr[i].state
      if tr[i].kind == "settle" and a.pos[q0] ~= 0 and b.pos[q0] == a.pos[q0] - W then
        -- поднял ли фонтан (а не толчок Лапидусом): Лапидус не сдвинулся вверх вместе
        return false
      end
    end
    return true
  end
end
local function selfPlug(rowPred)
  return function(lvl_, st, ns)
    if ns.dead then return true end
    if screwed(ns) then return true end
    local c = fountain(ns)
    for _, b in ipairs(ns.body) do if c[b] then local _, y = R.xy(lvl, b); if rowPred(y) then return false end end end
    return true
  end
end
-- держит деталь в столбе собой (узко) — по ярусу
local function holdAt(rowPred)
  return function(lvl_, st, ns)
    if ns.dead then return true end
    local c = fountain(ns)
    local body = {}; for _, b in ipairs(ns.body) do body[b] = true end
    for q, p in ipairs(lvl.pieces) do local x = ns.pos[q]
      if p.movable and x ~= 0 and not ns.fixed[q] and c[x] then
        -- над деталью (через детали) — тело
        local y0 = x; while y0 ~= 0 and not body[y0] and (c[y0] or ns.pos[q] == y0 or true) do
          local nx = lvl.nb[y0][1]; if nx == 0 then break end
          if body[nx] then local _, yy = R.xy(lvl, x); if rowPred(yy) then return false end end
          local occ = false; for r = 1, #ns.pos do if ns.pos[r] == nx then occ = true end end
          if not occ then break end
          y0 = nx
        end
      end
    end
    return true
  end
end
local tests = {
  { "Лапидуса не поднимает фонтан (узко: подъём тела струёй)", lapLifted },
  { "угольник не поднимает фонтан", pieceLifted("elb") },
  { "ниппель не поднимает фонтан", pieceLifted("nip") },
  { "заглушку не поднимает фонтан", pieceLifted("plug") },
  { "затыкать собой только внизу запрещено (строки ≥5)", selfPlug(function(y) return y >= 5 end) },
  { "затыкать собой только вверху запрещено (строки ≤4)", selfPlug(function(y) return y <= 4 end) },
  { "держать деталь (в т.ч. через детали) внизу запрещено", holdAt(function(y) return y >= 5 end) },
  { "держать деталь (в т.ч. через детали) вверху запрещено", holdAt(function(y) return y <= 4 end) },
}
for _, t in ipairs(tests) do
  local G = SV.explore(lvl, 3000000, t[2])
  if G and G.firstWin then print(string.format("РЕШАЕМ за %d (состояний %d): %s", G.depth[G.firstWin], G.n, t[1]))
  else print(string.format("нерешаем (состояний %d): %s", G and G.n or -1, t[1])) end
  if G then SV.freeGraph(G) end
end
