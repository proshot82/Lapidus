-- build/l8a/filt.lua — узкие фильтры ходов для абляций и контролей кв. 8 «Брандспойт».
-- Фильтр получает (lvl, st, ns) и возвращает false, если переход запрещён (solver/solve.lua, M.explore).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local F = {}

-- Вариант правил, в котором свободный конец Лапидуса не бьёт струёй (брандспойт выключен); остальное — как в core/rules.lua.
local function patched(from, to)
  local f = assert(io.open("core/rules.lua")):read("*a")
  local a, b = f:find(from, 1, true)
  assert(a, "patch: не найдено место")
  f = f:sub(1, a - 1) .. to .. f:sub(b + 1)
  return assert(load(f, "=rules_patched"))()
end
local NOHOSE = patched("jets[#jets + 1] = { cell = L.cell, dir = L.dir, cells = cells, lapidus = L.lapidus }",
  "if not L.lapidus then jets[#jets + 1] = { cell = L.cell, dir = L.dir, cells = cells, lapidus = L.lapidus } end")
F.NOHOSE = NOHOSE

-- ход, давший ns из st (любой из подходящих), и его результат по другим правилам
local function sameUnder(R2, lvl, st, ns)
  local k = R.key(ns)
  local lvl2 = F._lvl2 and F._lvl2[lvl] or nil
  if not lvl2 then F._lvl2 = F._lvl2 or setmetatable({}, { __mode = "k" }); lvl2 = R2.compile(lvl.def); F._lvl2[lvl] = lvl2 end
  for m = 1, 8 do
    local mv = R.MOVES[m]
    local s1 = R.move(lvl, st, mv.which, mv.dir)
    if s1 and R.key(s1) == k then
      local s2 = R2.move(lvl2, st, mv.which, mv.dir)
      if s2 and R2.key(s2) == k then return true end
    end
  end
  return false
end

-- Абляция «брандспойт не бьёт»: разрешён только переход, который получился бы и без струи из свободного конца Лапидуса.
function F.noHose(lvl, st, ns) return sameUnder(NOHOSE, lvl, st, ns) end

-- Лапидус прикручен к мокрому (брандспойт включён) в состоянии ns?
function F.hoseOn(lvl, ns)
  if ns.dead then return false end
  local w = R.water(lvl, ns)
  return w.lapWet and ((w.headQ ~= nil) ~= (w.heelQ ~= nil))
end

return F
