-- cfg.lua файл.lua [N] — перепись по точным конфигурациям деталей (клетки, закреплённость, свинченность): сколько
-- живых / скрытых / видимых состояний (Лапидус — любой), и правило видимого (fvis.why). Вывод инструмента.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = dofile("build/l7c/c_p2b_plus/fvis.lua")
local def = dofile(arg[1])
local TOP = tonumber(arg[2] or 40)
local why = V.why(def)
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local P = lvl.pieces
local function cfg(st)
  local t = {}
  for q, p in ipairs(P) do
    if p.movable then
      local c = st.pos[q]
      if c == 0 then t[#t + 1] = p.tag .. "=смыт" else
        local x, y = R.xy(lvl, c)
        local m = ""
        for r, p2 in ipairs(P) do if r ~= q and p2.movable and st.pos[r] ~= 0 and not st.fixed[q] and not st.fixed[r] and st.asm[q] == st.asm[r] then m = m .. "+" .. p2.tag end end
        t[#t + 1] = string.format("%s%d,%d%s%s", p.tag:sub(1, 1), x, y, st.fixed[q] and "F" or "", m)
      end
    end
  end
  return table.concat(t, " ")
end
local C = {}
for i = 1, G.n do
  if G.flag[i] ~= 2 then
    local st = R.decode(lvl, G.keys[i])
    local k = cfg(st)
    local c = C[k]; if not c then c = { k = k, live = 0, hid = 0, vis = 0, tag = "" }; C[k] = c end
    if good[i] == 1 then c.live = c.live + 1 else
      local w = why(lvl, st)
      if w then c.vis = c.vis + 1; if not c.tag:find(w, 1, true) then c.tag = c.tag .. w .. " " end else c.hid = c.hid + 1 end
    end
  end
end
local l = {}
for _, c in pairs(C) do l[#l + 1] = c end
table.sort(l, function(a, b) return (a.live + a.hid) > (b.live + b.hid) end)
local tl, th = 0, 0
for _, c in ipairs(l) do tl = tl + c.live; th = th + c.hid end
print(string.format("конфигураций %d; живых %d, скрытых %d", #l, tl, th))
print(" живых скрытых видимых | конфигурация | правила видимого")
for i = 1, math.min(TOP, #l) do local c = l[i]; print(string.format("%6d %6d %6d | %s | %s", c.live, c.hid, c.vis, c.k, c.tag)) end
SV.freeGraph(G); require("ffi").C.free(good)
