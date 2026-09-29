-- build/l7v_g/bear.lua файл.lua — несущность ошибок: фильтр, запрещающий ошибку, — как меняются обезьяна и доля скрытых.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local def = dofile(arg[1])
local lvl = R.compile(def)
local qe, qn
for k, p in ipairs(lvl.pieces) do if p.tag == "elb" then qe = k elseif p.tag == "nip" then qn = k end end
local function y(c) local _, yy = R.xy(lvl, c); return yy end
local tests = {
  { "без фильтра", nil },
  { "детали не падают в нижнюю комнату (левее столба)", function(_, st, ns)
      if ns.dead then return true end
      for _, q in ipairs({ qe, qn }) do local x, yy = R.xy(lvl, ns.pos[q]); if yy >= 5 and x <= 8 then return false end end return true end },
  { "угольник не входит в шахту раньше ниппеля", function(_, st, ns)
      if ns.dead then return true end
      local x, yy = R.xy(lvl, ns.pos[qe]); local nx, ny = R.xy(lvl, ns.pos[qn])
      if x == 9 and yy >= 4 and not (nx == 9 and ny > yy) then return false end return true end },
  { "оба запрета", function(_, st, ns)
      if ns.dead then return true end
      for _, q in ipairs({ qe, qn }) do local x, yy = R.xy(lvl, ns.pos[q]); if yy >= 5 and x <= 8 then return false end end
      local x, yy = R.xy(lvl, ns.pos[qe]); local nx, ny = R.xy(lvl, ns.pos[qn])
      if x == 9 and yy >= 4 and not (nx == 9 and ny > yy) then return false end return true end },
}
for _, t in ipairs(tests) do
  local G = SV.explore(lvl, 3000000, t[2])
  if not G.firstWin then print("нерешаем: " .. t[1]) else
    local good = SV.goodSet(G)
    local VL = V.compute(lvl, G, def, good)
    local m = V.measure(G, good, VL.newbie)
    print(string.format("%-50s ходов %d n=%6d живых %d скрытых %d (%.1f %%) обезьяна %.4f глуб %d", t[1], m.opt, G.n, m.live, m.hid, m.hiddenPct, m.smart, m.maxDeep))
    require("ffi").C.free(good)
  end
  SV.freeGraph(G)
end
