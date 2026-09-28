-- verify_groups.lua файл.lua — группировка скрытых/живых состояний по конфигурации деталей (проверка честности visibleLoss)
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local function cfg(s)
  local t = {}
  for q, p in ipairs(lvl.pieces) do if p.movable then
    local x, y = R.xy(lvl, s.pos[q]); t[#t+1] = string.format("%s(%d,%d)%s", p.tag, x, y, s.fixed[q] and "F" or "") end end
  return table.concat(t, " ")
end
local grp = {}
for i = 1, G.n do if G.flag[i] == 0 then
  local s = R.decode(lvl, G.keys[i])
  local lost = false
  for q, p in ipairs(lvl.pieces) do if p.movable and s.pos[q] == 0 then lost = true end end
  if not lost and def.visibleLoss then lost = def.visibleLoss(lvl, s) end
  local c = cfg(s)
  grp[c] = grp[c] or { live = 0, hid = 0, vis = 0 }
  if good[i] == 1 then grp[c].live = grp[c].live + 1 elseif lost then grp[c].vis = grp[c].vis + 1 else grp[c].hid = grp[c].hid + 1 end
end end
local l = {}
for c, g in pairs(grp) do if g.hid > 0 or g.live > 0 then l[#l+1] = { c, g } end end
table.sort(l, function(a, b) return a[1] < b[1] end)
for _, e in ipairs(l) do print(string.format("%-28s live %4d hid %4d vis %4d", e[1], e[2].live, e[2].hid, e[2].vis)) end
