-- build/l7v_g/cls.lua файл.lua [cfgsubstr] — скрытые классы: сколько живых с той же раскладкой деталей; почему тупик.
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
local function body(s) local t = {} for _, c in ipairs(s.body) do local x, y = R.xy(lvl, c); t[#t+1] = x .. y end; return table.concat(t, "-") .. (s.fixed and "" or "") end
local agg = {}
for i = 1, G.n do
  if G.flag[i] ~= 2 then
    local s = R.decode(lvl, G.keys[i]); local k = cfg(s)
    local a = agg[k] or { live = 0, hid = 0, vis = 0, ex = {} }; agg[k] = a
    if good[i] == 1 then a.live = a.live + 1 elseif VL.newbie[i] then a.vis = a.vis + 1 else a.hid = a.hid + 1; if #a.ex < 3 then a.ex[#a.ex+1] = body(s) end end
  end
end
local l = {}
for k, a in pairs(agg) do if a.hid > 0 then l[#l+1] = { k, a } end end
table.sort(l, function(x, y) return x[2].hid > y[2].hid end)
for _, e in ipairs(l) do print(string.format("%5d скр %5d жив %5d вид  %s   тело(пример): %s", e[2].hid, e[2].live, e[2].vis, e[1], table.concat(e[2].ex, " | "))) end
SV.freeGraph(G); require("ffi").C.free(good)
