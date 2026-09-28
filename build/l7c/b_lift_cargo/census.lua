-- census.lua файл.lua [mine|wide] — перепись состояний по конфигурации деталей (без решений):
-- для каждой конфигурации деталей: всего / живых / видимых тупиков / скрытых тупиков.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
if arg[2] then local V = dofile("build/l7c/b_lift_cargo/vis.lua"); def.visibleLoss = V.make(arg[2]) end
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local function lost(st)
  for q, p in ipairs(lvl.pieces) do if p.movable and st.pos[q] == 0 then return true end end
  return def.visibleLoss and def.visibleLoss(lvl, st) or false
end
local function cfg(st)
  local t = {}
  for q, p in ipairs(lvl.pieces) do if p.movable then
    if st.pos[q] == 0 then t[#t+1] = (p.tag or "?") .. "(смыт)" else
    local x, y = R.xy(lvl, st.pos[q]); t[#t+1] = string.format("%s(%d,%d)%s", p.tag or "?", x, y, st.fixed[q] and "F" or "") end end end
  return table.concat(t, " ")
end
local rows = {}
local tot = { n = 0, live = 0, vis = 0, hid = 0 }
for i = 1, G.n do
  if G.flag[i] ~= 2 then
    local st = R.decode(lvl, G.keys[i])
    local k = cfg(st)
    local r = rows[k] or { n = 0, live = 0, vis = 0, hid = 0 }
    rows[k] = r
    r.n = r.n + 1; tot.n = tot.n + 1
    if good[i] == 1 then r.live = r.live + 1; tot.live = tot.live + 1
    elseif lost(st) then r.vis = r.vis + 1; tot.vis = tot.vis + 1
    else r.hid = r.hid + 1; tot.hid = tot.hid + 1 end
  end
end
local l = {}
for k, r in pairs(rows) do l[#l+1] = { k, r } end
local key = os.getenv("SORT") or "n"
if os.getenv("ONLY") then local f = {} for _, e in ipairs(l) do if e[2][os.getenv("ONLY")] > 0 then f[#f+1] = e end end l = f end
table.sort(l, function(a, b) return a[2][key] > b[2][key] end)
print(string.format("всего %d: живых %d, видимых %d, скрытых %d (скрытых среди нерешённых невидимых %.0f %%)",
  tot.n, tot.live, tot.vis, tot.hid, 100 * tot.hid / math.max(1, tot.hid + tot.live)))
for i = 1, math.min(tonumber(os.getenv("TOP") or 30), #l) do
  local k, r = l[i][1], l[i][2]
  print(string.format("%6d  жив %6d  вид %6d  скр %6d   %s", r.n, r.live, r.vis, r.hid, k))
end
SV.freeGraph(G); require("ffi").C.free(good)
