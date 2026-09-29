-- build/l7d/cand.lua — сборка кандидата кв. 7 из ASCII (build/l7c/d_tee_lift/mk.lua) с абляциями доводки (29.09).
-- local C = dofile("build/l7d/cand.lua"); return C.build{ rows = {...}, R = 3 }
-- Абляции: без заглушки; без угольника; угольник не катается на фонтане; деталь под телом в столбе не удержать (узкая);
-- в основании фонтана деталь не удержать. Правил visibleLoss нет — считается общая линейка tools/vislib.lua.
local MK = dofile("build/l7c/d_tee_lift/mk.lua")
local C = {}
local legend = {
  S = { kind = "source", ports = { right = "V" } },
  ["="] = { kind = "pipe", what = "pipe", ports = { left = "N", right = "V" } },
  T = { kind = "pipe", what = "tee", ports = { left = "N", up = "V", right = "V" } },
  F = { kind = "fixture", what = "bath", ports = { up = "V" } },
  q = { kind = "fitting", what = "plug", tag = "plug", ports = { left = "N" } },
  e = { kind = "fitting", what = "elbow", tag = "elb", ports = { down = "N", right = "N" } },
}
local function find(lvl, what) for q, p in ipairs(lvl.pieces) do if p.what == what then return q end end end
local function row(lvl, c) return math.floor((c - 1) / lvl.W) + 1 end
local function elbowStaysLow(lvl, st, ns)
  local q = find(lvl, "elbow"); local c = ns.pos[q]
  return c == 0 or row(lvl, c) >= row(lvl, lvl.pieces[q].start)
end
local function fountain(lvl, ns)
  local R = require("core.rules"); local col = {}
  for _, j in ipairs(R.jets(lvl, ns)) do
    if j.dir == R.UP and not j.lapidus then for _, c in ipairs(j.cells) do col[c] = true end end
  end
  return col
end
-- «Деталь под телом в столбе не удержать»: незакреплённая деталь в столбе фонтана, а над ней — клетка Лапидуса.
local function noHold(lvl, st, ns)
  if ns.dead then return true end
  local col = fountain(lvl, ns); local b = {}
  for _, c in ipairs(ns.body) do b[c] = true end
  for q, p in ipairs(lvl.pieces) do
    local c = ns.pos[q]
    if p.movable and c ~= 0 and not ns.fixed[q] and col[c] and b[lvl.nb[c][1]] then return false end
  end
  return true
end
local function noLid(lvl, st, ns)
  if ns.dead then return true end
  local c1 = lvl.nb[lvl.pieces[find(lvl, "tee")].start][1]
  for q, p in ipairs(lvl.pieces) do if p.movable and ns.pos[q] == c1 and not ns.fixed[q] then return false end end
  return true
end
C.ablations = {
  { name = "без заглушки", remove = "plug" },
  { name = "без угольника", remove = "elb" },
  { name = "угольник не катается на фонтане", filter = elbowStaysLow },
  { name = "деталь под телом в столбе не удержать", filter = noHold },
  { name = "в основании фонтана деталь не удержать", filter = noLid },
}
C.noHold, C.noLid, C.elbowStaysLow = noHold, noLid, elbowStaysLow
function C.build(t)
  local lg = {}
  for k, v in pairs(legend) do lg[k] = v end
  for k, v in pairs(t.legend or {}) do lg[k] = v end
  local def = MK.build{ rows = t.rows, legend = lg, R = t.R or 3, L = t.L }
  def.ablations = C.ablations
  def.visibleLoss = t.visibleLoss
  def.target = { moves = { 15, 40 }, states = 50000, dead = 55, fb = 3 }
  return def
end
return C
