-- build/l7e/cand.lua — сборка кандидата кв. 7 (раунд 3) из ASCII через build/l7c/d_tee_lift/mk.lua.
-- local C = dofile("build/l7e/cand.lua"); return C.build{ rows = {...}, R = 3, L = {2,5} }
-- Легенда (можно дополнять через t.legend):
--   S стояк (выход вправо V) · = труба · T тройник (вверх V, вправо V) · F прибор (вход сверху V) · G прибор (вход слева V)
--   D прибор (вход снизу V) · e угольник (вниз Н, вправо Н) · q заглушка (влево Н) · p заглушка (влево В)
--   n ниппель горизонтальный (влево Н, вправо Н) · m муфта (влево Н, вправо В) · v ниппель вертикальный (вниз Н, вверх В)
-- Абляции: удаление каждой детали; «угольник не катается на фонтане»; «деталь под телом в столбе не удержать» (узкая);
-- «в основании фонтана деталь не удержать». Правил visibleLoss нет — считается общая линейка tools/vislib.lua.
local MK = dofile("build/l7c/d_tee_lift/mk.lua")
local C = {}
local legend = {
  S = { kind = "source", ports = { right = "V" } },
  ["="] = { kind = "pipe", what = "pipe", ports = { left = "N", right = "V" } },
  T = { kind = "pipe", what = "tee", ports = { left = "N", up = "V", right = "V" } },
  F = { kind = "fixture", what = "bath", ports = { up = "V" } },
  G = { kind = "fixture", what = "bath", ports = { left = "V" } },
  D = { kind = "fixture", what = "bath", ports = { down = "V" } },
  q = { kind = "fitting", what = "plug", tag = "plug", ports = { left = "N" } },
  p = { kind = "fitting", what = "plug", tag = "plug", ports = { left = "V" } },
  e = { kind = "fitting", what = "elbow", tag = "elb", ports = { down = "N", right = "N" } },
  n = { kind = "fitting", what = "nipple", tag = "nip", ports = { left = "N", right = "N" } },
  m = { kind = "fitting", what = "coupling", tag = "cpl", ports = { left = "N", right = "V" } },
  v = { kind = "fitting", what = "nipple", tag = "nip", ports = { down = "N", up = "V" } },
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
C.noHold, C.noLid, C.elbowStaysLow = noHold, noLid, elbowStaysLow
function C.build(t)
  local lg = {}
  for k, v in pairs(legend) do lg[k] = v end
  for k, v in pairs(t.legend or {}) do lg[k] = v end
  local def = MK.build{ rows = t.rows, legend = lg, R = t.R or 3, L = t.L }
  local abl = {}
  for _, o in ipairs(def.objects) do
    if o.kind == "fitting" then abl[#abl + 1] = { name = "без детали " .. o.tag, remove = o.tag } end
  end
  abl[#abl + 1] = { name = "угольник не катается на фонтане", filter = elbowStaysLow }
  abl[#abl + 1] = { name = "деталь под телом в столбе не удержать", filter = noHold }
  abl[#abl + 1] = { name = "в основании фонтана деталь не удержать", filter = noLid }
  def.ablations = abl
  def.visibleLoss = t.visibleLoss
  def.target = { moves = { 15, 40 }, states = 50000, dead = 55, fb = 3 }
  return def
end
return C
