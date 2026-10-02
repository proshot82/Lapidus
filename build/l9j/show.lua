-- build/l9j/show.lua файл.lua — стартовая раскладка и клетки, где бывает тело Лапидуса (*), по всему графу.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local st0 = R.newState(lvl)
local G = SV.explore(lvl, 3000000)
local reach = {}
local preach = {}
for i = 1, G.n do if G.flag[i] ~= 2 then local st = R.decode(lvl, G.keys[i]); for _, c in ipairs(st.body) do reach[c] = true end
  for q = 1, #st.pos do if st.pos[q] ~= 0 then preach[st.pos[q]] = (preach[st.pos[q]] or "") .. lvl.pieces[q].kind:sub(1,1) end end end end
local SYM = { source = "S", fixture = "F", stub = "T", pipe = "=", fitting = "b", porcelain = "P" }
for y = 1, lvl.H do
  local a, b = {}, {}
  for x = 1, lvl.W do
    local i = (y - 1) * lvl.W + x
    local c = lvl.cell[i]
    local ch = c == 1 and "#" or (c == 2 and "~" or ".")
    local ch2 = ch
    if reach[i] then ch2 = "*" end
    for q, p in ipairs(lvl.pieces) do if st0.pos[q] == i then ch = p.tag and p.tag:sub(1,1) or SYM[p.kind] end end
    for k, c2 in ipairs(st0.body) do if c2 == i then ch = (k == #st0.body) and "H" or (k == 1 and "f" or "o") end end
    a[#a+1] = ch; b[#b+1] = ch2
  end
  print(table.concat(a) .. "   " .. table.concat(b))
end
print("состояний", G.n, "решение", G.firstWin and G.depth[G.firstWin] or "нет")
SV.freeGraph(G)
