-- peek.lua файл.lua "tag=x,y ..." [N] — нарисовать до N скрытых (новичок) состояний с заданной расстановкой деталей (ТОЛЬКО вывод).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local GN = dofile("build/l7c/d_tee_lift/gnov.lua")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local nov = GN.compute(lvl, G, def)
local want = {}
for tok in (arg[2] or ""):gmatch("%S+") do local t, x, y = tok:match("^(%w+)=(%d+),(%d+)$"); want[t] = R.idx(lvl, tonumber(x), tonumber(y)) end
local SYM = { source = "S", fixture = "F", pipe = "=" }
local shown = 0
for i = 1, G.n do
  if G.flag[i] == 0 and good[i] == 0 and not nov[i] then
    local st = R.decode(lvl, G.keys[i])
    local ok = true
    for q, p in ipairs(lvl.pieces) do if p.tag and want[p.tag] and st.pos[q] ~= want[p.tag] then ok = false end end
    if ok then
      shown = shown + 1
      local rows = {}
      for y = 1, lvl.H do rows[y] = {} for x = 1, lvl.W do local c = lvl.cell[(y-1)*lvl.W+x]; rows[y][x] = c == 1 and "#" or (c == 2 and "~" or ".") end end
      for _, j in ipairs(R.jets(lvl, st)) do for _, c in ipairs(j.cells) do local x, y = R.xy(lvl, c); rows[y][x] = (j.dir == 1 or j.dir == 3) and "|" or "-" end end
      for q, pp in ipairs(lvl.pieces) do if st.pos[q] ~= 0 then local x, y = R.xy(lvl, st.pos[q]); local ch
        if pp.movable then ch = pp.tag; ch = st.fixed[q] and ch:upper() or ch else ch = SYM[pp.kind] end; rows[y][x] = ch end end
      for k, c in ipairs(st.body) do local x, y = R.xy(lvl, c); rows[y][x] = (k == #st.body) and "H" or ((k == 1) and "f" or "o") end
      print("#" .. i .. " глубина " .. G.depth[i])
      for y = 1, lvl.H do print("  " .. table.concat(rows[y])) end
      if shown >= tonumber(arg[3] or 4) then break end
    end
  end
end
SV.freeGraph(G)
