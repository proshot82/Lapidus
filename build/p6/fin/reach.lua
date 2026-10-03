-- достижимые конфигурации деталей (сводка) — luajit reach.lua файл
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local cnt = {}
for i = 1, G.n do
  if G.flag[i] ~= 2 then
    local st = R.decode(lvl, G.keys[i])
    local t = {}
    for q, p in ipairs(lvl.pieces) do if p.movable then
      if st.pos[q] == 0 then t[#t+1] = p.tag .. ":смыт" else
      local x, y = R.xy(lvl, st.pos[q]); t[#t+1] = string.format("%s(%d,%d)%s", p.tag, x, y, st.fixed[q] and "F" or "") end end end
    local k = table.concat(t, " ")
    cnt[k] = (cnt[k] or 0) + 1
  end
end
local l = {}
for k, v in pairs(cnt) do if k:find("F") then l[#l+1] = k .. "  " .. v end end
table.sort(l)
for _, s in ipairs(l) do print(s) end
print("всего", G.n, G.firstWin and "реш" or "нереш")
