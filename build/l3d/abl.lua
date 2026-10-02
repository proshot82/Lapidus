-- build/l3d/abl.lua файл — контроли (должны оставаться решаемыми) и «несущность» ошибок плана:
-- фильтр, запрещающий саму ошибку, — насколько легче становится уровень (умная обезьяна, доля скрытых). Без ходов.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local def = dofile(arg[1])
local lvl = R.compile(def)
local W = lvl.W
local function cell(x, y) return (y - 1) * W + x end
local function soaps(s) local t = {} for q, p in ipairs(lvl.pieces) do if p.porcelain then t[#t + 1] = q end end return t end
local SO = soaps()
local function soapAbove(s, c) local up = lvl.nb[c][1]; for _, q in ipairs(SO) do if s.pos[q] == up then return true end end return false end
local F = {
  { "контроль: мыло не толкать влево", function(l, st, ns)
      for _, q in ipairs(SO) do if st.pos[q] ~= 0 and ns.pos[q] ~= 0 and ns.pos[q] == lvl.nb[st.pos[q]][4] then return false end end
      return true end },
  { "контроль: ноги не заходят в (2,6)", function(l, st, ns) return ns.body[1] ~= cell(2, 6) end },
  { "контроль: мыло не поднимать в нишу (5,3)", function(l, st, ns) for _, q in ipairs(SO) do if ns.pos[q] == cell(5, 3) then return false end end return true end },
  { "ошибка 1 запрещена: подставку не смыть, пока на ней нет мыла", function(l, st, ns)
      for _, q in ipairs(SO) do if st.pos[q] ~= 0 and ns.pos[q] == 0 and not soapAbove(st, st.pos[q]) then return false end end return true end },
  { "ошибка 2 запрещена: подставку из-под мыла не выбить вбок", function(l, st, ns)
      for _, q in ipairs(SO) do if st.pos[q] == cell(5, 7) and ns.pos[q] == cell(4, 7) and soapAbove(st, cell(5, 7)) then return false end end return true end },
}
local function measure(filter)
  local G = SV.explore(lvl, 3000000, filter)
  if not G or not G.firstWin then local n = G and G.n; SV.freeGraph(G); return nil, n end
  local good = SV.goodSet(G)
  local VL = V.compute(lvl, G, def, good)
  local m = V.measure(G, good, VL.newbie)
  SV.freeGraph(G); require("ffi").C.free(good)
  return m
end
local b = measure(nil)
print(string.format("база: ходов %d, скрытых %.1f %%, обезьяна %.3f %%", b.opt, b.hiddenPct, b.smart))
for _, f in ipairs(F) do
  local m, n = measure(f[2])
  if not m then print(string.format("%-58s НЕРЕШАЕМ (состояний %s)", f[1], tostring(n)))
  else print(string.format("%-58s ходов %d, скрытых %.1f %%, обезьяна %.3f %%", f[1], m.opt, m.hiddenPct, m.smart)) end
end
