-- build/l7v_g/wins.lua — выигрышные состояния F38: конфигурация деталей, тело Лапидуса, глубина (единственность).
package.path = "./?.lua;" .. package.path
local R = require("core.rules"); local SV = require("solver.solve")
local def = dofile("build/l7f/F38.lua"); local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
for i = 1, G.n do if G.flag[i] == 1 then local s = R.decode(lvl, G.keys[i]); local t = {}
  for q, p in ipairs(lvl.pieces) do if p.movable then local x, y = R.xy(lvl, s.pos[q]); t[#t+1] = p.tag..x..","..y..(s.fixed[q] and "F" or "") end end
  local b = {} for _, c in ipairs(s.body) do local x, y = R.xy(lvl, c); b[#b+1] = x..","..y end
  print(G.depth[i], table.concat(t, " "), "длина тела " .. #b, "тело-ключ " .. table.concat(b, ""):len()) end end
