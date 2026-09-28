-- hid.lua файл.lua [N] — какие конфигурации деталей дают скрытые тупики (для себя, без решений):
-- для каждой конфигурации: живых / скрытых / видимых, мин. глубина.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local function lost(st)
  for q, p in ipairs(lvl.pieces) do if p.movable and st.pos[q] == 0 then return true end end
  return def.visibleLoss and def.visibleLoss(lvl, st) or false
end
local agg = {}
for i = 1, G.n do
  if G.flag[i] ~= 2 then
    local st = R.decode(lvl, G.keys[i])
    local t = {}
    for q, p in ipairs(lvl.pieces) do if p.movable then
      if st.pos[q] == 0 then t[#t+1] = (p.tag or p.what) .. "=x" else
        local x, y = R.xy(lvl, st.pos[q]); t[#t+1] = string.format("%s(%d,%d)%s", p.tag or p.what, x, y, st.fixed[q] and "F" or "") end end end
    local k = table.concat(t, " ")
    local a = agg[k] or { live = 0, hid = 0, vis = 0, d = 1e9 }; agg[k] = a
    if good[i] == 1 then a.live = a.live + 1 elseif lost(st) then a.vis = a.vis + 1 else a.hid = a.hid + 1 end
    if G.depth[i] < a.d then a.d = G.depth[i] end
  end
end
local list = {}
for k, a in pairs(agg) do if a.hid > 0 or arg[3] == "all" then list[#list+1] = { k, a } end end
table.sort(list, function(a, b) return a[2].hid > b[2].hid end)
for i = 1, math.min(tonumber(arg[2] or 20), #list) do local a = list[i][2]; print(string.format("%-40s live=%5d hid=%5d vis=%5d d=%3d", list[i][1], a.live, a.hid, a.vis, a.d)) end
SV.freeGraph(G); require("ffi").C.free(good)
