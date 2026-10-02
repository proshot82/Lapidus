-- verify_census.lua файл.lua — скрытые тупики по конфигурациям деталей (проверка честности visibleLoss).
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
local function cfg(s)
  local t = {}
  for q, p in ipairs(lvl.pieces) do if p.movable then
    local x, y = R.xy(lvl, s.pos[q]); t[#t+1] = string.format("%s(%d,%d)%s", p.tag, x, y, s.fixed[q] and "F" or "") end end
  return table.concat(t, " ")
end
local H, L, falsevis = {}, {}, 0
for i = 1, G.n do if G.flag[i] ~= 2 then
  local st = R.decode(lvl, G.keys[i])
  if good[i] == 1 then L[cfg(st)] = (L[cfg(st)] or 0) + 1; if lost(st) then falsevis = falsevis + 1 end
  elseif not lost(st) then H[cfg(st)] = (H[cfg(st)] or 0) + 1 end
end end
print("живые состояния, помеченные видимыми: " .. falsevis)
local l = {} for k, v in pairs(H) do l[#l+1] = { k, v, L[k] or 0 } end
table.sort(l, function(a, b) return a[2] > b[2] end)
for _, r in ipairs(l) do print(string.format("скрытых %4d  (живых в той же конфигурации %4d)  %s", r[2], r[3], r[1])) end
