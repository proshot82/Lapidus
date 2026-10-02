-- build/l1c/inspect.lua файл.lua x,y — служебный: состояния, где конец Лапидуса стоит в клетке x,y, их классы
-- (живое / O / P) и первые предки вне этой клетки. Только для изучения механики; кадров решения не печатает.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local tx, ty = arg[2]:match("(%d+),(%d+)")
local target = R.idx(lvl, tonumber(tx), tonumber(ty))
local function show(st)
  local t = {}
  for i, c in ipairs(st.body) do local x, y = R.xy(lvl, c); t[#t + 1] = string.format("%d,%d", x, y) end
  return "ноги " .. table.concat(t, " ") .. " голова"
end
local n = 0
for i = 1, G.n do
  if G.flag[i] ~= 2 then
    local st = R.decode(lvl, G.keys[i])
    local hit = false
    for _, c in ipairs(st.body) do if c == target then hit = true end end
    if hit and n < tonumber(arg[3] or 12) then
      n = n + 1
      print(string.format("%s  %s  глубина %d", good[i] == 1 and "ЖИВ" or "мёртв", show(st), G.depth[i]))
    end
  end
end
