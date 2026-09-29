-- build/l7f/why.lua файл.lua "подстрока раскладки" — из первого мёртвого состояния с такой раскладкой: какие раскладки достижимы дальше
-- (и сколько состояний), плюс допустимые ходы из него. Только терминал.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local function cfg(s)
  local t = {}
  for q, p in ipairs(lvl.pieces) do if p.movable then
    if s.pos[q] == 0 then t[#t+1] = p.tag .. "=смыт" else
    local x, y = R.xy(lvl, s.pos[q]); t[#t+1] = string.format("%s(%d,%d)%s", p.tag, x, y, s.fixed[q] and "F" or "") end end end
  return table.concat(t, " ")
end
local function body(s) local t = {} for _, c in ipairs(s.body) do local x, y = R.xy(lvl, c); t[#t+1] = x .. "," .. y end; return table.concat(t, " ") end
local want = arg[2]
local ES, E = G.eStart.p, G.edges.p
local start
for i = 1, G.n do if G.flag[i] == 0 and good[i] ~= 1 then local s = R.decode(lvl, G.keys[i]); if cfg(s):find(want, 1, true) then start = i; print("состояние " .. i .. " глубина " .. G.depth[i] .. ": " .. cfg(s) .. " | тело " .. body(s)); break end end end
if not start then print("нет мёртвых состояний с такой раскладкой") return end
local seen, q, h = { [start] = true }, { start }, 1
local agg = {}
while h <= #q do
  local u = q[h]; h = h + 1
  local s = R.decode(lvl, G.keys[u]); local k = cfg(s); agg[k] = (agg[k] or 0) + 1
  for e = ES[u-1], ES[u]-1 do local v = E[e]; if not seen[v] and G.flag[v] ~= 2 then seen[v] = true; q[#q+1] = v end end
end
local l = {}
for k, n in pairs(agg) do l[#l+1] = { k, n } end
table.sort(l, function(a, b) return a[2] > b[2] end)
print("достижимо состояний " .. #q .. ", раскладок " .. #l)
for i = 1, math.min(25, #l) do print(string.format("  %5d  %s", l[i][2], l[i][1])) end
SV.freeGraph(G); require("ffi").C.free(good)
