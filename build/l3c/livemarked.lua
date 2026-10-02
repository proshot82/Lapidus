-- build/l3c/livemarked.lua уровень.lua vis=файл — показать живые состояния, помеченные правилом как проигрыш (кадры в вывод)
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local rule = dofile(arg[2]:sub(5))
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local shown = 0
for i = 1, G.n do
  if G.flag[i] == 0 and good[i] == 1 then
    local st = R.decode(lvl, G.keys[i])
    if rule(lvl, st) then
      shown = shown + 1
      if shown <= 6 then
        local rows = {}
        for y = 1, lvl.H do rows[y] = {} for x = 1, lvl.W do local c = lvl.cell[(y-1)*lvl.W+x]; rows[y][x] = c == 1 and "#" or (c == 2 and "~" or ".") end end
        for q, p in ipairs(lvl.pieces) do if st.pos[q] ~= 0 then local x, y = R.xy(lvl, st.pos[q]); rows[y][x] = p.porcelain and "p" or (p.source and "S" or "F") end end
        for k, c in ipairs(st.body) do local x, y = R.xy(lvl, c); rows[y][x] = (k == #st.body) and "H" or (k == 1 and "f" or "o") end
        for y = 1, lvl.H do print(table.concat(rows[y])) end
        print()
      end
    end
  end
end
print("живых помечено:", shown)
