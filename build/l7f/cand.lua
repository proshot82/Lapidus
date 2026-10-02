-- build/l7f/cand.lua — сборка кандидата кв. 7 (раунд 4, ядро на M9) из ASCII через build/l7c/d_tee_lift/mk.lua.
-- local C = dofile("build/l7f/cand.lua"); return C.build{ rows = {...}, R = 3, L = {2,5}, legend = {...}, abl = {...} }
-- Легенда по умолчанию (дополняется через t.legend):
--   S стояк (вправо V) · = труба (влево N, вправо V) · T тройник (влево N, вверх V, вправо V) · U труба-колено (влево N, вверх V)
--   F/G/D/K прибор со входом сверху/слева/снизу/справа (V)
--   e угольник (вниз N, вправо N) · w угольник (вниз N, влево N) · g угольник (вниз N, вправо V) · h угольник (вниз N, влево V)
--   j угольник (вверх N, вправо N) · k угольник (вверх N, влево N) · z угольник (вверх N, вправо V)
--   c заглушка (вниз N) · q заглушка (влево N) · b заглушка (вправо N) · p заглушка (влево V) · d заглушка (вверх N)
--   n ниппель (влево N, вправо N) · v ниппель (вниз N, вверх V) · r ниппель (вниз V, вверх N) · m муфта (влево N, вправо V)
-- Абляции: удаление каждой детали + узкие фильтры из t.abl = { {name, filter}, ... } (см. build/l7f/filt.lua).
local MK = dofile("build/l7c/d_tee_lift/mk.lua")
local C = {}
local legend = {
  S = { kind = "source", ports = { right = "V" } },
  ["="] = { kind = "pipe", what = "pipe", ports = { left = "N", right = "V" } },
  T = { kind = "pipe", what = "tee", ports = { left = "N", up = "V", right = "V" } },
  U = { kind = "pipe", what = "pipe", ports = { left = "N", up = "V" } },
  F = { kind = "fixture", what = "bath", ports = { up = "V" } },
  G = { kind = "fixture", what = "bath", ports = { left = "V" } },
  D = { kind = "fixture", what = "bath", ports = { down = "V" } },
  K = { kind = "fixture", what = "bath", ports = { right = "V" } },
  e = { kind = "fitting", what = "elbow", tag = "elb", ports = { down = "N", right = "N" } },
  w = { kind = "fitting", what = "elbow", tag = "elb", ports = { down = "N", left = "N" } },
  g = { kind = "fitting", what = "elbow", tag = "elb", ports = { down = "N", right = "V" } },
  h = { kind = "fitting", what = "elbow", tag = "elb", ports = { down = "N", left = "V" } },
  j = { kind = "fitting", what = "elbow", tag = "elb2", ports = { up = "N", right = "N" } },
  k = { kind = "fitting", what = "elbow", tag = "elb2", ports = { up = "N", left = "N" } },
  z = { kind = "fitting", what = "elbow", tag = "elb2", ports = { up = "N", right = "V" } },
  c = { kind = "fitting", what = "plug", tag = "plug", ports = { down = "N" } },
  q = { kind = "fitting", what = "plug", tag = "plug", ports = { left = "N" } },
  b = { kind = "fitting", what = "plug", tag = "plug", ports = { right = "N" } },
  p = { kind = "fitting", what = "plug", tag = "plug", ports = { left = "V" } },
  d = { kind = "fitting", what = "plug", tag = "plug", ports = { up = "N" } },
  n = { kind = "fitting", what = "nipple", tag = "nip", ports = { left = "N", right = "N" } },
  v = { kind = "fitting", what = "nipple", tag = "nip", ports = { down = "N", up = "V" } },
  r = { kind = "fitting", what = "nipple", tag = "nip", ports = { down = "V", up = "N" } },
  m = { kind = "fitting", what = "coupling", tag = "cpl", ports = { left = "N", right = "V" } },
}
function C.build(t)
  local lg = {}
  for k, v in pairs(legend) do lg[k] = v end
  for k, v in pairs(t.legend or {}) do lg[k] = v end
  local def = MK.build{ rows = t.rows, legend = lg, R = t.R or 3, L = t.L }
  local abl = {}
  for _, o in ipairs(def.objects) do
    if o.kind == "fitting" then abl[#abl + 1] = { name = "без детали " .. o.tag, remove = o.tag } end
  end
  for _, a in ipairs(t.abl or {}) do abl[#abl + 1] = { name = a[1], filter = a[2] } end
  def.ablations = abl
  def.visibleLoss = t.visibleLoss
  def.target = { moves = { 15, 40 }, states = 50000, dead = 55, fb = 3 }
  return def
end
return C
