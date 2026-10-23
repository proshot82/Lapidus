-- дополнительные абляции и достижимость ключевых положений (только метрики)
local L = dofile("build/l10v/lib.lua")
local R = L.R
local path = arg[1] or "build/p6/fin/final.lua"
local def0 = dofile(path)
local lvl0 = R.compile(def0)
local function q(lvl, tag) for i, p in ipairs(lvl.pieces) do if p.tag == tag then return i end end end
local function onBody(lvl, ns, c) local below = lvl.nb[c][3]; for _, b in ipairs(ns.body) do if b == below then return true end end; return false end
local F = {}
F["ниппель никогда не лежит на Лапидусе (свободный)"] = function(lvl, st, ns) local n = q(lvl, "nip"); local c = ns.pos[n]
  return c == 0 or ns.fixed[n] or not onBody(lvl, ns, c) end
F["муфта никогда не лежит на Лапидусе (свободная)"] = function(lvl, st, ns) local n = q(lvl, "cpl"); local c = ns.pos[n]
  return c == 0 or ns.fixed[n] or not onBody(lvl, ns, c) end
F["ниппель не спускается на Лапидусе, x=8, ниже ряда 3"] = function(lvl, st, ns) local n = q(lvl, "nip"); local c = ns.pos[n]
  if c == 0 or ns.fixed[n] then return true end; local x, y = R.xy(lvl, c); return not (x == 8 and y >= 4 and onBody(lvl, ns, c)) end
F["Лапидус не входит в коридор через x=9"] = function(lvl, st, ns) for _, b in ipairs(ns.body) do local x, y = R.xy(lvl, b); if x == 9 and y == 6 then return false end end; return true end
F["муфта не закрепляется раньше, чем Лапидус в коридоре"] = function(lvl, st, ns) local c = q(lvl, "cpl")
  if not ns.fixed[c] or st.fixed[c] then return true end
  for _, b in ipairs(ns.body) do local x, y = R.xy(lvl, b); if y == 6 and x <= 7 then return true end end; return false end
F["ниппель и муфта никогда не свинчены вместе свободными"] = function(lvl, st, ns) local c, n = q(lvl, "cpl"), q(lvl, "nip")
  return ns.pos[c] == 0 or ns.pos[n] == 0 or ns.fixed[c] or ns.asm[c] ~= ns.asm[n] end
F["тело Лапидуса никогда не в шахте x=8 ниже ряда 4 до закрепления муфты"] = function(lvl, st, ns) local c = q(lvl, "cpl")
  if ns.fixed[c] then return true end; for _, b in ipairs(ns.body) do local x, y = R.xy(lvl, b); if x == 8 and y >= 5 then return false end end; return true end
local names = {}; for k in pairs(F) do names[#names+1] = k end; table.sort(names)
for _, k in ipairs(names) do
  local def = dofile(path)
  local S = L.load(def, { filter = F[k] })
  print(string.format("%-62s %s (состояний %d)", k, S.G.firstWin and ("РЕШАЕМ за " .. S:opt()) or "нерешаем", S.n))
  S:free()
end
