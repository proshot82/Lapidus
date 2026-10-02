-- build/l7v_e/frz.lua файл.lua [k1] — обобщение «замёрзла» из линейки: нужная незакреплённая деталь не на месте
-- «замёрзла», если её сдвиг возможен только через видимый проигрыш (итерация до неподвижной точки).
-- С аргументом k1 — сначала помечается класс K1 (угольник прикручен раньше, чем закрыт боковой выход).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
V.POCKET = tonumber(os.getenv("POCKET") or 3)
local VL = V.compute(lvl, G, def, good)
local Q = {}; for q, p in ipairs(lvl.pieces) do if p.tag then Q[p.tag] = q end end
local lost = {}
for i = 1, G.n do if G.flag[i] ~= 2 then lost[i] = VL.newbie[i]
  if arg[2] == "k1" and good[i] ~= 1 then local s = VL.states[i]; if s.fixed[Q.elb] and not s.fixed[Q.plug] then lost[i] = true end end end end
local function show(t) local m = V.measure(G, good, lost); print(string.format("%s: скрытых %d = %.1f %%, обезьяна %.3f, глубина %d [%s]", t, m.hid, m.hiddenPct, m.smart, m.maxDeep, m.deepList)) end
show("старт")
for it = 1, 30 do
  local add = {}
  for _, q in ipairs(VL.needed) do
    local goal = VL.win.pos[q]
    -- canMove: из состояния по невидимым состояниям достижимо невидимое состояние, где q стоит иначе
    local mv = {}
    for i = 1, G.n do if G.flag[i] ~= 2 and not lost[i] then
      for e = G.eStart.p[i-1], G.eStart.p[i]-1 do local j = G.edges.p[e]
        if G.flag[j] ~= 2 and (not lost[j] or G.flag[j] == 1) and VL.states[j].pos[q] ~= VL.states[i].pos[q] then mv[i] = true break end end end end
    -- обратное замыкание по рёбрам между невидимыми
    local changed = true
    while changed do changed = false
      for i = 1, G.n do if G.flag[i] ~= 2 and not lost[i] and not mv[i] then
        for e = G.eStart.p[i-1], G.eStart.p[i]-1 do local j = G.edges.p[e]
          if mv[j] and not lost[j] then mv[i] = true; changed = true break end end end end end
    for i = 1, G.n do if G.flag[i] ~= 2 and not lost[i] and good[i] ~= 1 then local s = VL.states[i]
      if not s.fixed[q] and s.pos[q] ~= goal and not mv[i] then add[i] = true end end end
  end
  local n = 0; for i in pairs(add) do lost[i] = true; n = n + 1 end
  show("итерация " .. it .. " (+" .. n .. ")")
  if n == 0 then break end
end
