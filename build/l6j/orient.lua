-- build/l6j/orient.lua файл.lua "cpl(3,7)F nip(7,5)F" — для состояний с данной конфигурацией: сколько живых/скрытых/видимых
-- по положению концов (какой конец стоит на клетке (x,y), заданной 3-м и 4-м аргументами).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local VL = V.compute(lvl, G, def, good)
local want, cx, cy = arg[2], tonumber(arg[3]), tonumber(arg[4])
local cell = R.idx(lvl, cx, cy)
local function cfg(st)
  local t = {}
  for q, p in ipairs(lvl.pieces) do if p.movable then
    if st.pos[q] == 0 then t[#t+1] = (p.tag or p.what) .. "=смыт" else
      local x, y = R.xy(lvl, st.pos[q]); t[#t+1] = string.format("%s(%d,%d)%s", p.tag or p.what, x, y, st.fixed[q] and "F" or "") end end end
  return table.concat(t, " ")
end
local agg = {}
for i = 1, G.n do
  if G.flag[i] ~= 2 then
    local st = R.decode(lvl, G.keys[i])
    if cfg(st) == want then
      local b = st.body
      local k = (b[#b] == cell) and "голова на клетке" or ((b[1] == cell) and "ноги на клетке" or "никто")
      local a = agg[k] or { 0, 0, 0 }; agg[k] = a
      if good[i] == 1 then a[1] = a[1] + 1 elseif VL.newbie[i] then a[3] = a[3] + 1 else a[2] = a[2] + 1 end
    end
  end
end
for k, a in pairs(agg) do print(string.format("%-18s живых %4d скрытых %4d видимых %4d", k, a[1], a[2], a[3])) end
