-- build/l4d/abl_frames.lua файл.lua имя_абляции — кратчайшее решение уровня с применённой абляцией (кадры, только терминал).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local d2 = SV.deepcopy(def)
for _, ab in ipairs(def.ablations) do if ab.name == arg[2] then SV.applyAblation(d2, ab); d2.ablations = nil end end
local lvl = R.compile(d2)
local G = SV.explore(lvl, 3000000)
if not G.firstWin then print("нерешаем") return end
local path, x = {}, G.firstWin
while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
table.insert(path, 1, 1)
local last
for _, s in ipairs(path) do
  local st = R.decode(lvl, G.keys[s])
  local t = {}
  for q, p in ipairs(lvl.pieces) do if p.movable then local xx, yy = R.xy(lvl, st.pos[q]); t[#t+1] = string.format("%s(%d,%d)%s", p.tag, xx, yy, st.fixed[q] and "F" or "") end end
  local k = table.concat(t, " ")
  if k ~= last then print(G.depth[s] .. ": " .. k); last = k end
end
