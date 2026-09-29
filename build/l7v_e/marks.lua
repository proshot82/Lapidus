-- build/l7v_e/marks.lua файл.lua — метрики при расширенной разметке (классы, которые новичок, возможно, видит сразу).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local VL = V.compute(lvl, G, def, good)
local Q = {}; for q, p in ipairs(lvl.pieces) do if p.tag then Q[p.tag] = q end end
local E, P = Q.elb, Q.plug
local function xy(c) if c == 0 then return 0, 0 end return R.xy(lvl, c) end
local classes = {
  { "K1 угольник прикручен, а боковой выход открыт", function(s) return s.fixed[E] and not s.fixed[P] end },
  { "K2 угольник внизу у основания (x<=4,y=6), пробка не на месте", function(s) local x,y = xy(s.pos[E]); return y==6 and x<=4 and not s.fixed[P] end },
  { "K3 обе детали в шахте над столбом (y<=3)", function(s) local x1,y1=xy(s.pos[E]); local x2,y2=xy(s.pos[P]); return x1==5 and x2==5 and y1<=3 and y2<=3 end },
  { "K4 пробка прямо над угольником в колонке 5", function(s) local x1,y1=xy(s.pos[E]); local x2,y2=xy(s.pos[P]); return x1==5 and x2==5 and y2==y1-1 and not s.fixed[E] end },
}
local function report(name, extra)
  local lost = {}
  local add = 0
  for i = 1, G.n do if G.flag[i] ~= 2 then
    local st = VL.states[i]
    local l = VL.newbie[i]
    if not l and extra and extra(st) then
      if good[i] == 1 then l = false else l = true; add = add + 1 end
    end
    lost[i] = l
  end end
  local m = V.measure(G, good, lost)
  print(string.format("%-60s +%5d | скрытых %5d = %4.1f %% | обезьяна %.3f %% | глубина %d [%s]", name, add, m.hid, m.hiddenPct, m.smart, m.maxDeep, m.deepList))
  return lost
end
report("линейка (как есть)")
local live = {}
for _, c in ipairs(classes) do
  -- сколько живых в классе (если >0, класс не «видимый проигрыш»)
  local lv, dd = 0, 0
  for i = 1, G.n do if G.flag[i] ~= 2 and c[2](VL.states[i]) then if good[i]==1 then lv=lv+1 elseif not VL.newbie[i] then dd=dd+1 end end end
  print(string.format("   %s: живых в классе %d, скрытых %d", c[1], lv, dd))
  report(c[1], c[2])
end
report("K1+K2", function(s) return classes[1][2](s) or classes[2][2](s) end)
report("K1+K2+K3", function(s) return classes[1][2](s) or classes[2][2](s) or classes[3][2](s) end)
report("K1..K4", function(s) for _, c in ipairs(classes) do if c[2](s) then return true end end end)
report("знаток", function(s) return false end)
