-- solvefrom.lua файл ход1 ход2 ... — применить ходы, затем показать кратчайшее продолжение до победы (кадры, только в терминал).
package.path = "./?.lua;" .. package.path
local R = require("core.rules"); local SV = require("solver.solve"); local MK = dofile("build/l2d/mk.lua")
local d = dofile(arg[1]); if d.rows then d = MK.build(d.rows, d.opts) end
local lvl = R.compile(d); local G = SV.explore(lvl, 3000000)
local st = R.newState(lvl); local DIR = { u = 1, r = 2, d = 3, l = 4 }
for i = 2, #arg do local m = arg[i]; local ns = assert(R.move(lvl, st, m:sub(1,1) == "f" and "heel" or "head", DIR[m:sub(2,2)]), "отказ " .. m); st = ns end
local idx = {}; for i = 1, G.n do idx[G.keys[i]] = i end
local s0 = assert(idx[R.key(st)], "состояние не найдено")
local prev, q, h = { [s0] = 0 }, { s0 }, 1; local win
while h <= #q do local u = q[h]; h = h + 1; if G.flag[u] == 1 then win = u break end
  for e = G.eStart.p[u-1], G.eStart.p[u]-1 do local v = G.edges.p[e]; if prev[v] == nil then prev[v] = u; q[#q+1] = v end end end
if not win then print("отсюда победы нет; достижимо " .. #q) return end
local path = {}; local x = win; while x ~= s0 do table.insert(path, 1, x); x = prev[x] end; table.insert(path, 1, s0)
local function show(s, label)
  local rows = {}
  for y = 1, lvl.H do rows[y] = {} for x = 1, lvl.W do local c = lvl.cell[(y-1)*lvl.W+x]; rows[y][x] = c == 1 and "#" or (c == 2 and "~" or ".") end end
  for qq, pp in ipairs(lvl.pieces) do if s.pos[qq] ~= 0 then local x, y = R.xy(lvl, s.pos[qq]); local ch = ({ source = "S", fixture = "F", stub = "T", fitting = "b" })[pp.kind] or "?"; if pp.kind == "stub" then for k in pairs(pp.ports) do ch = ({"^",">","v","<"})[k] end end; if pp.movable then ch = s.fixed[qq] and "B" or "b" end; rows[y][x] = ch end end
  if not s.dead then for i, c in ipairs(s.body) do local x, y = R.xy(lvl, c); rows[y][x] = (i == #s.body) and "H" or ((i == 1) and "f" or "o") end end
  local out = { label }; for y = 1, lvl.H do out[#out+1] = table.concat(rows[y]) end; return out
end
local frames = {}
for i, id in ipairs(path) do frames[#frames+1] = show(R.decode(lvl, G.keys[id]), i == 1 and "from" or tostring(i-1)) end
local per = math.max(1, math.floor(110 / (lvl.W + 2)))
for k = 1, #frames, per do for line = 1, #frames[k] do local parts = {}; for j = k, math.min(k+per-1, #frames) do parts[#parts+1] = string.format("%-" .. (lvl.W+2) .. "s", frames[j][line] or "") end; print(table.concat(parts, "")) end; print() end
