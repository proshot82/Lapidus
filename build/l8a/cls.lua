-- build/l8a/cls.lua файл.lua [N] — классы состояний по раскладке деталей: живых / скрытых / видимых (топ N по каждому), только терминал.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local def = dofile(arg[1])
local N = tonumber(arg[2] or 12)
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local VL = V.compute(lvl, G, def, good)
local function cfg(s)
  local t = {}
  for q, p in ipairs(lvl.pieces) do if p.movable then
    if s.pos[q] == 0 then t[#t+1] = p.tag .. "=смыт" else
    local x, y = R.xy(lvl, s.pos[q]); t[#t+1] = string.format("%s(%d,%d)%s", p.tag, x, y, s.fixed[q] and "F" or "") end end end
  return table.concat(t, " ")
end
local agg, tot = {}, { live = 0, hid = 0, vis = 0 }
for i = 1, G.n do
  if G.flag[i] ~= 2 then
    local s = R.decode(lvl, G.keys[i]); local k = cfg(s)
    local a = agg[k] or { live = 0, hid = 0, vis = 0 }; agg[k] = a
    if good[i] == 1 then a.live = a.live + 1; tot.live = tot.live + 1 elseif VL.newbie[i] then a.vis = a.vis + 1; tot.vis = tot.vis + 1 else a.hid = a.hid + 1; tot.hid = tot.hid + 1 end
  end
end
print(string.format("живых %d, скрытых %d, видимых %d; counts: frozen %d goal %d washed %d", tot.live, tot.hid, tot.vis, VL.counts.frozen, VL.counts.goal, VL.counts.washed))
for _, kind in ipairs({ "hid", "vis", "live" }) do
  local l = {}
  for k, a in pairs(agg) do if a[kind] > 0 then l[#l+1] = { k, a } end end
  table.sort(l, function(x, y) return x[2][kind] > y[2][kind] end)
  print("== топ " .. kind)
  for i = 1, math.min(N, #l) do local e = l[i]; print(string.format("  %5d скр %5d жив %5d вид  %s", e[2].hid, e[2].live, e[2].vis, e[1])) end
end
SV.freeGraph(G); require("ffi").C.free(good)
