-- build/l8j/census.lua файл.lua — конфигурации деталей: сколько состояний, живых, видимых, скрытых (мерка новичка).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local VL = G.firstWin and V.compute(lvl, G, def, good) or { newbie = {} }
local cnt = {}
for i = 1, G.n do
  if G.flag[i] ~= 2 then
    local st = R.decode(lvl, G.keys[i])
    local t = {}
    for q, p in ipairs(lvl.pieces) do if p.movable then
      local x, y = R.xy(lvl, st.pos[q]); t[#t + 1] = (p.tag or "?") .. (st.pos[q] == 0 and "-" or string.format("(%d,%d)%s", x, y, st.fixed[q] and "F" or "")) end end
    local k = table.concat(t, " ")
    local c = cnt[k] or { n = 0, live = 0, vis = 0, hid = 0 }
    cnt[k] = c
    c.n = c.n + 1
    if good[i] == 1 then c.live = c.live + 1 elseif VL.newbie[i] then c.vis = c.vis + 1 else c.hid = c.hid + 1 end
  end
end
local l = {}
for k, c in pairs(cnt) do l[#l + 1] = { k, c } end
table.sort(l, function(a, b) return a[2].n > b[2].n end)
local filt = arg[2]
for _, e in ipairs(l) do
  if not filt or e[1]:find(filt, 1, true) then
    print(string.format("%-40s всего %5d живых %5d видимых %5d скрытых %5d", e[1], e[2].n, e[2].live, e[2].vis, e[2].hid))
  end
end
