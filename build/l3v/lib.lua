-- build/l3v/lib.lua — общие заготовки слепого скептика кв. 3 (29.09.2026).
-- Ничего не печатает про порядок ходов; даёт граф, разметку и описания конфигураций мыла.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local L = {}

function L.load(path, cap)
  local def = dofile(path or "levels/03.lua")
  local lvl = R.compile(def)
  local G = SV.explore(lvl, cap or 3000000)
  assert(G, "cap")
  local good = SV.goodSet(G)
  local VL = V.compute(lvl, G, def, good)
  local sts = {}
  for i = 1, G.n do if G.flag[i] ~= 2 then sts[i] = R.decode(lvl, G.keys[i]) end end
  local ctx = { def = def, lvl = lvl, G = G, good = good, VL = VL, sts = sts, R = R, SV = SV, V = V }
  -- индексы мыла: 3 — верхнее (стартует на полке), 4 — нижнее (стартует на полу)
  ctx.soaps = {}
  for q, p in ipairs(lvl.pieces) do if p.porcelain then ctx.soaps[#ctx.soaps + 1] = q end end
  return ctx
end

function L.xy(ctx, c) return R.xy(ctx.lvl, c) end

-- что под клеткой: "wall" / "pit" / "lap" / "soap" / "empty"
function L.below(ctx, st, c)
  local lvl = ctx.lvl
  local b = lvl.nb[c][3]
  if b == 0 or lvl.cell[b] == 1 then return "wall" end
  if lvl.cell[b] == 2 then return "pit" end
  for _, c2 in ipairs(st.body) do if c2 == b then return "lap" end end
  for _, q in ipairs(ctx.soaps) do if st.pos[q] == b then return "soap" end end
  return "empty"
end

-- описание мыла q: "washed" | "(x,y)/под:wall|lap|soap"
function L.soapDesc(ctx, st, q)
  local c = st.pos[q]
  if c == 0 then return "смыто" end
  local x, y = R.xy(ctx.lvl, c)
  return string.format("(%d,%d)/%s", x, y, L.below(ctx, st, c))
end

function L.cfg(ctx, st)
  local t = {}
  for _, q in ipairs(ctx.soaps) do t[#t + 1] = L.soapDesc(ctx, st, q) end
  return table.concat(t, " ")
end

-- класс состояния: только положения мыла (без Лапидуса)
function L.soapOnly(ctx, st)
  local t = {}
  for _, q in ipairs(ctx.soaps) do
    local c = st.pos[q]
    if c == 0 then t[#t + 1] = "смыто" else local x, y = R.xy(ctx.lvl, c); t[#t + 1] = string.format("(%d,%d)", x, y) end
  end
  return table.concat(t, " ")
end

-- статус состояния i: "live" | "vis" | "hid" | "wash" | "win"
function L.status(ctx, i)
  local G = ctx.G
  if G.flag[i] == 2 then return "wash" end
  if G.flag[i] == 1 then return "win" end
  if ctx.good[i] == 1 then return "live" end
  if ctx.VL.newbie[i] then return "vis" end
  return "hid"
end

function L.edges(ctx, i)
  local G = ctx.G
  local out = {}
  for e = G.eStart.p[i - 1], G.eStart.p[i] - 1 do out[#out + 1] = G.edges.p[e] end
  return out
end

-- умная обезьяна из состояния s0 за T ходов по разметке lostArr (как в check.lua)
function L.monkey(ctx, s0, T, lostArr)
  local G = ctx.G
  lostArr = lostArr or ctx.VL.newbie
  local p, ok = { [s0] = 1.0 }, 0
  for _ = 1, T do
    local np = {}
    for i, pr in pairs(p) do
      local cand = {}
      for e = G.eStart.p[i - 1], G.eStart.p[i] - 1 do
        local j = G.edges.p[e]
        if G.flag[j] == 1 then cand[#cand + 1] = j elseif G.flag[j] ~= 2 and not lostArr[j] then cand[#cand + 1] = j end
      end
      if #cand == 0 then np[i] = (np[i] or 0) + pr else
        local share = pr / #cand
        for _, j in ipairs(cand) do if G.flag[j] == 1 then ok = ok + share else np[j] = (np[j] or 0) + share end end
      end
    end
    p = np
  end
  local live, dead = 0, 0
  for i, pr in pairs(p) do if ctx.good[i] == 1 then live = live + pr else dead = dead + pr end end
  return ok, live, dead
end

-- кратчайший путь (список id состояний)
function L.path(ctx)
  local G = ctx.G
  local path, x = {}, G.firstWin
  while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
  table.insert(path, 1, 1)
  return path
end

function L.free(ctx) ctx.SV.freeGraph(ctx.G); require("ffi").C.free(ctx.good) end

return L
