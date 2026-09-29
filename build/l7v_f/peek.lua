-- build/l7v_f/peek.lua файл.lua "подстрока-конфигурации" [N] — показать N скрытых состояний класса и их соседей (только терминал).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local VL = V.compute(lvl, G, def, good)
local function cfg(s)
  local t = {}
  for q, p in ipairs(lvl.pieces) do if p.movable then
    if s.pos[q] == 0 then t[#t+1] = p.tag .. "=смыт" else
    local x, y = R.xy(lvl, s.pos[q]); t[#t+1] = string.format("%s(%d,%d)%s%s", p.tag, x, y, s.fixed[q] and "F" or "", "a"..s.asm[q]) end end end
  return table.concat(t, " ")
end
local SYM = { nip = "n", elb = "e", plug = "p" }
local function show(s)
  local rows = {}
  for y = 1, lvl.H do rows[y] = {} for x = 1, lvl.W do local c = lvl.cell[(y-1)*lvl.W+x]; rows[y][x] = c == 1 and "#" or "." end end
  for q, pp in ipairs(lvl.pieces) do if s.pos[q] ~= 0 then local x, y = R.xy(lvl, s.pos[q]); local ch = SYM[pp.tag] or "T"; if s.fixed[q] and pp.movable then ch = ch:upper() end; rows[y][x] = ch end end
  for i, c in ipairs(s.body) do local x, y = R.xy(lvl, c); rows[y][x] = (i == #s.body) and "H" or ((i == 1) and "f" or "o") end
  local o = {} for y = 1, lvl.H do o[#o+1] = table.concat(rows[y]) end
  return o
end
local want, N, k = arg[2], tonumber(arg[3] or 2), 0
for i = 1, G.n do
  if G.flag[i] == 0 and good[i] ~= 1 and not VL.newbie[i] then
    local s = R.decode(lvl, G.keys[i])
    if cfg(s):find(want, 1, true) then
      k = k + 1; if k > N then break end
      print("--- скрытое " .. cfg(s))
      local fr = { show(s) }
      for e = G.eStart.p[i-1], G.eStart.p[i]-1 do local j = G.edges.p[e]
        if G.flag[j] ~= 2 then fr[#fr+1] = show(R.decode(lvl, G.keys[j])) end end
      for line = 1, lvl.H do local p = {} for _, f in ipairs(fr) do p[#p+1] = f[line] .. "  " end print(table.concat(p)) end
    end
  end
end
SV.freeGraph(G); require("ffi").C.free(good)
