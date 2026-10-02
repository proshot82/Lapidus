-- build/l8b/mk.lua — сборка кандидата кв. 8 «Брандспойт» (поиск ядра «переходник на кране», 16×10) из ASCII.
-- local C = dofile("build/l8b/mk.lua"); return C.build{ rows = {...}, R = 2, L = {2,6}, abl = {{имя, фильтр}}, controls = {...}, visibleLoss = f, texts = {...} }
-- Легенда: стены # слив ~ пусто . ; f ноги, H голова, o звенья.
--   Краны (source): S вправо V · Y влево V · s вправо N · y влево N · A вверх V · a вверх N · D вниз V · d вниз N
--   Прибор (ванна, V): F вход сверху · G вход слева · K вход справа · B вход снизу
--   Глухой отвод (stub): X влево N · Z вправо N · x влево V · z вправо V · ^ вверх N
--   Детали: n ниппель (влево N, вправо N) · c муфта (влево V, вправо V) · q пробка (влево N) · b пробка (вправо N)
--           p пробка (влево V) · r пробка (вправо V) · u пробка (вверх N) · t пробка (вниз N) · v ниппель вертикальный (вниз N, вверх N)
--           m переходник (влево N, вправо V) · i переходник (влево V, вправо N) · e угольник (вниз N, вправо N) · w угольник (вниз N, влево N)
--           j угольник (вверх N, вправо N) · k угольник (вверх N, влево N)
local MK = dofile("build/l7c/d_tee_lift/mk.lua")
local C = {}
C.legend = {
  S = { kind = "source", ports = { right = "V" } }, Y = { kind = "source", ports = { left = "V" } },
  s = { kind = "source", ports = { right = "N" } }, y = { kind = "source", ports = { left = "N" } },
  A = { kind = "source", ports = { up = "V" } }, a = { kind = "source", ports = { up = "N" } },
  D = { kind = "source", ports = { down = "V" } }, d = { kind = "source", ports = { down = "N" } },
  F = { kind = "fixture", what = "bath", ports = { up = "V" } }, G = { kind = "fixture", what = "bath", ports = { left = "V" } },
  K = { kind = "fixture", what = "bath", ports = { right = "V" } }, B = { kind = "fixture", what = "bath", ports = { down = "V" } },
  X = { kind = "stub", what = "stub", ports = { left = "N" } }, Z = { kind = "stub", what = "stub", ports = { right = "N" } },
  x = { kind = "stub", what = "stub", ports = { left = "V" } }, z = { kind = "stub", what = "stub", ports = { right = "V" } },
  ["^"] = { kind = "stub", what = "stub", ports = { up = "N" } },
  n = { kind = "fitting", what = "nipple", tag = "nip", ports = { left = "N", right = "N" } },
  v = { kind = "fitting", what = "nipple", tag = "nip", ports = { down = "N", up = "N" } },
  c = { kind = "fitting", what = "coupling", tag = "cpl", ports = { left = "V", right = "V" } },
  q = { kind = "fitting", what = "plug", tag = "plug", ports = { left = "N" } },
  b = { kind = "fitting", what = "plug", tag = "plug", ports = { right = "N" } },
  p = { kind = "fitting", what = "plug", tag = "plug", ports = { left = "V" } },
  r = { kind = "fitting", what = "plug", tag = "plug", ports = { right = "V" } },
  u = { kind = "fitting", what = "plug", tag = "plug", ports = { up = "N" } },
  t = { kind = "fitting", what = "plug", tag = "plug", ports = { down = "N" } },
  m = { kind = "fitting", what = "nipple", tag = "adp", ports = { left = "N", right = "V" } },
  i = { kind = "fitting", what = "nipple", tag = "adp", ports = { left = "V", right = "N" } },
  e = { kind = "fitting", what = "elbow", tag = "elb", ports = { down = "N", right = "N" } },
  w = { kind = "fitting", what = "elbow", tag = "elb", ports = { down = "N", left = "N" } },
  j = { kind = "fitting", what = "elbow", tag = "elb", ports = { up = "N", right = "N" } },
  k = { kind = "fitting", what = "elbow", tag = "elb", ports = { up = "N", left = "N" } },
}
function C.build(t)
  local lg = {}
  for k, v in pairs(C.legend) do lg[k] = v end
  for k, v in pairs(t.legend or {}) do lg[k] = v end
  local def = MK.build{ rows = t.rows, legend = lg, R = t.R or 2, L = t.L or { 2, 6 } }
  def.id, def.flat, def.name, def.tile = 8, 8, "Брандспойт", "mint"
  def.target = { moves = { 15, 40 }, states = 200000, dead = 55, fb = 3 }
  local abl = {}
  if not t.noRemove then
    for _, o in ipairs(def.objects) do
      if o.kind == "fitting" then abl[#abl + 1] = { name = "без детали " .. o.tag, remove = o.tag } end
    end
  end
  for _, a in ipairs(t.abl or {}) do abl[#abl + 1] = { name = a[1], filter = a[2] } end
  def.ablations = abl
  def.controls = t.controls
  def.visibleLoss = t.visibleLoss
  def.texts = t.texts or { request = "", card = "card08", hints = { "", "", "" } }
  return def
end
-- быстрый фильтр для абляции «брандспойт не бьёт»
C.F = dofile("build/l8a/filt.lua")
return C
