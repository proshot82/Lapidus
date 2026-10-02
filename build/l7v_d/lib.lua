-- build/l7v_d/lib.lua — заготовки слепого скептика кандидата кв. 7 L7D (29.09.2026).
-- Ничего не печатает про порядок ходов; даёт граф, разметку и описания конфигураций деталей.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local L = {}

function L.load(path, cap)
  local def = dofile(path or "build/l7c/d_tee_lift/L7D.lua")
  local lvl = R.compile(def)
  local G = SV.explore(lvl, cap or 3000000)
  assert(G, "cap")
  local good = SV.goodSet(G)
  local VL = V.compute(lvl, G, def, good)
  local sts = {}
  for i = 1, G.n do if G.flag[i] ~= 2 then sts[i] = R.decode(lvl, G.keys[i]) end end
  local ctx = { def = def, lvl = lvl, G = G, good = good, VL = VL, sts = sts, R = R, SV = SV, V = V }
  ctx.q = {}
  for q, p in ipairs(lvl.pieces) do
    if p.what then ctx.q[p.what] = q end
    if p.tag then ctx.q[p.tag] = q end
    if p.fixture then ctx.q.bath = q end
    if p.source then ctx.q.src = q end
  end
  ctx.win = sts[G.firstWin]
  return ctx
end

function L.xy(ctx, c) return R.xy(ctx.lvl, c) end
function L.idx(ctx, x, y) return (y - 1) * ctx.lvl.W + x end

-- описание детали q: "смыто" | "(x,y)" + "F" если закреплена
function L.pieceDesc(ctx, st, q)
  local c = st.pos[q]
  if c == 0 then return "смыто" end
  local x, y = R.xy(ctx.lvl, c)
  return string.format("(%d,%d)%s", x, y, st.fixed[q] and "F" or "")
end

-- прикручен ли конец Лапидуса, и куда
function L.anchors(ctx, st)
  local piece = R.occupancy(st)
  local h = R.endScrew(ctx.lvl, st, piece, "head")
  local f = R.endScrew(ctx.lvl, st, piece, "heel")
  return h, f
end

function L.cfg(ctx, st)
  local t = {}
  for _, name in ipairs({ "elbow", "plug" }) do t[#t + 1] = name .. L.pieceDesc(ctx, st, ctx.q[name]) end
  local h, f = L.anchors(ctx, st)
  if h or f then t[#t + 1] = "якорь:" .. (h and ("голова→" .. (ctx.lvl.pieces[h].what or ctx.lvl.pieces[h].kind)) or "") .. (f and ("ноги→" .. (ctx.lvl.pieces[f].what or ctx.lvl.pieces[f].kind)) or "") end
  return table.concat(t, " ")
end

-- статус состояния i: "live" | "vis" | "hid" | "wash" | "win"
function L.status(ctx, i, lostArr)
  local G = ctx.G
  if G.flag[i] == 2 then return "wash" end
  if G.flag[i] == 1 then return "win" end
  if ctx.good[i] == 1 then return "live" end
  if (lostArr or ctx.VL.newbie)[i] then return "vis" end
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

-- множество достижимых из набора семян (вперёд)
function L.forward(ctx, seeds)
  local seen, q = {}, {}
  for _, i in ipairs(seeds) do if not seen[i] then seen[i] = true; q[#q + 1] = i end end
  local h = 1
  while h <= #q do
    local u = q[h]; h = h + 1
    for _, v in ipairs(L.edges(ctx, u)) do if not seen[v] then seen[v] = true; q[#q + 1] = v end end
  end
  return seen, q
end

function L.free(ctx) ctx.SV.freeGraph(ctx.G); require("ffi").C.free(ctx.good) end

return L
