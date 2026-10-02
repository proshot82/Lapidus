-- dbg2.lua файл.lua правило [N] — показать живые состояния, помеченные правилом (отладка разметки; вывод инструмента).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = dofile(os.getenv("VIS") or "build/l7c/c_p2b_plus/qvis.lua")
local def = dofile(arg[1])
local why = V.why(def, { adpStackVisible = true })
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local N = tonumber(arg[3] or 3)
local shown = 0
for i = 1, G.n do
  if shown >= N then break end
  if G.flag[i] == 0 and good[i] == 1 then
    local st = R.decode(lvl, G.keys[i])
    if why(lvl, st) == arg[2] then
      shown = shown + 1
      local rows = {}
      for y = 1, lvl.H do rows[y] = {} for x = 1, lvl.W do local c = lvl.cell[(y-1)*lvl.W+x]; rows[y][x] = c == 1 and "#" or "." end end
      for q, p in ipairs(lvl.pieces) do if st.pos[q] ~= 0 then local x, y = R.xy(lvl, st.pos[q]); local ch = p.tag and p.tag:sub(1,1) or (p.source and "S" or "F"); if p.movable and st.fixed[q] then ch = ch:upper() end; rows[y][x] = ch end end
      for j, c in ipairs(st.body) do local x, y = R.xy(lvl, c); rows[y][x] = (j == #st.body) and "H" or ((j == 1) and "f" or "o") end
      for y = 1, lvl.H do print(table.concat(rows[y])) end
      print()
    end
  end
end
SV.freeGraph(G); require("ffi").C.free(good)
