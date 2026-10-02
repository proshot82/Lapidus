-- build/l8a/mk8.lua — сборка кандидата кв. 8 «Брандспойт» из ASCII (поверх build/l7c/d_tee_lift/mk.lua).
-- local C = dofile("build/l8a/mk8.lua"); return C.build{ rows = {...}, R = 2, L = {2,5}, legend = {...}, abl = {...}, visibleLoss = f }
-- Легенда по умолчанию (дополняется через t.legend):
--   S стояк (вправо V) · A стояк (вверх V) · Y стояк (влево V) · = труба (влево N, вправо V) · | труба (вниз N, вверх V)
--   U колено (влево N, вверх V) · L колено (вправо N, вверх V) · T тройник (влево N, вверх V, вправо V)
--   F/G/D/K прибор со входом сверху/слева/снизу/справа (V) · X глухой отвод (влево N) · Z глухой отвод (вправо N)
--   e угольник (вниз N, вправо N) · w угольник (вниз N, влево N) · g угольник (вниз N, вправо V) · h угольник (вниз N, влево V)
--   j угольник (вверх N, вправо N) · k угольник (вверх N, влево N) · z угольник (вверх N, вправо V) · y угольник (вверх N, влево V)
--   c заглушка (вниз N) · q заглушка (влево N) · b заглушка (вправо N) · p заглушка (влево V) · d заглушка (вверх N)
--   n ниппель (влево N, вправо N) · v ниппель (вниз N, вверх V) · r ниппель (вниз V, вверх N) · m муфта (влево N, вправо V)
--   u муфта (вниз N, вверх V)? — нет: v. i ниппель (влево V, вправо N) · x муфта (влево V, вправо V)
local MK = dofile("build/l7c/d_tee_lift/mk.lua")
local C = {}
local legend = {
  S = { kind = "source", ports = { right = "V" } },
  A = { kind = "source", ports = { up = "V" } },
  Y = { kind = "source", ports = { left = "V" } },
  ["="] = { kind = "pipe", what = "pipe", ports = { left = "N", right = "V" } },
  ["|"] = { kind = "pipe", what = "pipe", ports = { down = "N", up = "V" } },
  U = { kind = "pipe", what = "pipe", ports = { left = "N", up = "V" } },
  L = { kind = "pipe", what = "pipe", ports = { right = "N", up = "V" } },
  T = { kind = "pipe", what = "tee", ports = { left = "N", up = "V", right = "V" } },
  F = { kind = "fixture", what = "bath", ports = { up = "V" } },
  G = { kind = "fixture", what = "bath", ports = { left = "V" } },
  D = { kind = "fixture", what = "bath", ports = { down = "V" } },
  K = { kind = "fixture", what = "bath", ports = { right = "V" } },
  X = { kind = "stub", what = "stub", ports = { left = "N" } },
  Z = { kind = "stub", what = "stub", ports = { right = "N" } },
  e = { kind = "fitting", what = "elbow", tag = "elb", ports = { down = "N", right = "N" } },
  w = { kind = "fitting", what = "elbow", tag = "elb", ports = { down = "N", left = "N" } },
  g = { kind = "fitting", what = "elbow", tag = "elb", ports = { down = "N", right = "V" } },
  h = { kind = "fitting", what = "elbow", tag = "elb", ports = { down = "N", left = "V" } },
  j = { kind = "fitting", what = "elbow", tag = "elb2", ports = { up = "N", right = "N" } },
  k = { kind = "fitting", what = "elbow", tag = "elb2", ports = { up = "N", left = "N" } },
  z = { kind = "fitting", what = "elbow", tag = "elb2", ports = { up = "N", right = "V" } },
  y = { kind = "fitting", what = "elbow", tag = "elb2", ports = { up = "N", left = "V" } },
  c = { kind = "fitting", what = "plug", tag = "plug", ports = { down = "N" } },
  q = { kind = "fitting", what = "plug", tag = "plug", ports = { left = "N" } },
  b = { kind = "fitting", what = "plug", tag = "plug", ports = { right = "N" } },
  p = { kind = "fitting", what = "plug", tag = "plug", ports = { left = "V" } },
  d = { kind = "fitting", what = "plug", tag = "plug", ports = { up = "N" } },
  n = { kind = "fitting", what = "nipple", tag = "nip", ports = { left = "N", right = "N" } },
  v = { kind = "fitting", what = "nipple", tag = "nip", ports = { down = "N", up = "V" } },
  r = { kind = "fitting", what = "nipple", tag = "nip", ports = { down = "V", up = "N" } },
  i = { kind = "fitting", what = "nipple", tag = "nip", ports = { left = "V", right = "N" } },
  m = { kind = "fitting", what = "coupling", tag = "cpl", ports = { left = "N", right = "V" } },
  x = { kind = "fitting", what = "coupling", tag = "cpl", ports = { left = "V", right = "V" } },
  P = { kind = "porcelain", what = "soap", tag = "soap" },
}
function C.build(t)
  local lg = {}
  for k, v in pairs(legend) do lg[k] = v end
  for k, v in pairs(t.legend or {}) do lg[k] = v end
  local def = MK.build{ rows = t.rows, legend = lg, R = t.R or 2, L = t.L or { 2, 5 } }
  def.id, def.flat, def.name = 8, 8, "Брандспойт"
  def.tile = "mint"
  local abl = {}
  for _, o in ipairs(def.objects) do
    if o.kind == "fitting" then abl[#abl + 1] = { name = "без детали " .. o.tag, remove = o.tag } end
  end
  for _, a in ipairs(t.abl or {}) do abl[#abl + 1] = { name = a[1], filter = a[2] } end
  def.ablations = abl
  def.controls = t.controls
  def.visibleLoss = t.visibleLoss
  def.target = { moves = { 15, 40 }, states = 50000, dead = 55, fb = 3 }
  def.texts = t.texts
  return def
end
return C
