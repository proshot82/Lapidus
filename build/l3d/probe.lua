-- build/l3d/probe.lua файл.lua x y — сколько достижимых состояний, где мыло лежит в (x,y), и где при этом бывают концы Лапидуса (только сводка).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local cx, cy = tonumber(arg[2]), tonumber(arg[3])
local target = (cy - 1) * lvl.W + cx
local n, ends = 0, {}
for i = 1, G.n do
  if G.flag[i] ~= 2 then
    local st = R.decode(lvl, G.keys[i])
    local has = false
    for q, p in ipairs(lvl.pieces) do if p.porcelain and st.pos[q] == target then has = true end end
    if has then
      n = n + 1
      local b = st.body
      local fx, fy = R.xy(lvl, b[1]); local hx, hy = R.xy(lvl, b[#b])
      local k = string.format("f(%d,%d)%s H(%d,%d)%s n%d", fx, fy, st.anchor and st.anchor[1] and "*" or "", hx, hy, st.anchor and st.anchor[2] and "*" or "", #b)
      ends[k] = (ends[k] or 0) + 1
    end
  end
end
print("состояний с мылом в клетке: " .. n)
local l = {}
for k, v in pairs(ends) do l[#l+1] = k .. " x" .. v end
table.sort(l)
print(table.concat(l, "\n"))
