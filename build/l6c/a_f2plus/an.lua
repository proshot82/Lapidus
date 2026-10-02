-- build/l6c/a_f2plus/an.lua файл.lua [show] — разбор кандидата по шагам кратчайшего пути (только вывод инструмента).
-- По каждому шагу: безопасных / скрытых / видимых / смыло; размер скрытой области за ошибкой; поток умной обезьяны.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local SYM = { source = "S", fixture = "F", stub = "T", pipe = "=", fitting = "b", porcelain = "P" }
local function show(s)
  local rows = {}
  for y = 1, lvl.H do rows[y] = {} for x = 1, lvl.W do local c = lvl.cell[(y-1)*lvl.W+x]; rows[y][x] = c == 1 and "#" or (c == 2 and "~" or ".") end end
  for q, pp in ipairs(lvl.pieces) do if s.pos[q] ~= 0 then local x, y = R.xy(lvl, s.pos[q]); local ch = (pp.tag and pp.tag:sub(1,1)) or SYM[pp.kind]; if not pp.movable then ch = SYM[pp.kind] end; if pp.movable then ch = s.fixed[q] and ch:upper() or ch:lower() end; rows[y][x] = ch end end
  if not s.dead then for i, c in ipairs(s.body) do local x, y = R.xy(lvl, c); rows[y][x] = (i == #s.body) and "H" or ((i == 1) and "f" or "o") end end
  local out = {}
  for y = 1, lvl.H do out[#out+1] = table.concat(rows[y]) end
  return out
end
local G = SV.explore(lvl, 3000000)
if not G then print("CAP") return end
if not G.firstWin then print("НЕРЕШАЕМ", G.n) return end
local good = SV.goodSet(G)
local states = {}
local function S(i) states[i] = states[i] or R.decode(lvl, G.keys[i]); return states[i] end
local function lost(st)
  for q, p in ipairs(lvl.pieces) do if p.movable and st.pos[q] == 0 then return true end end
  return def.visibleLoss and def.visibleLoss(lvl, st) or false
end
local path, x = {}, G.firstWin
while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
table.insert(path, 1, 1)
-- размер скрытой области (достижимые не-живые не-видимые состояния) от j
local function region(j)
  local seen, q, h = { [j] = true }, { j }, 1
  while h <= #q and #q < 100000 do
    local u = q[h]; h = h + 1
    for e = G.eStart.p[u - 1], G.eStart.p[u] - 1 do
      local v = G.edges.p[e]
      if not seen[v] and good[v] ~= 1 and G.flag[v] ~= 2 and not lost(S(v)) then seen[v] = true; q[#q+1] = v end
    end
  end
  return #q
end
print(table.concat(show(S(1)), "\n"))
local line = {}
for k = 1, #path - 1 do
  local s = path[k]
  local sf, hd, vs, wa, regs = 0, 0, 0, 0, {}
  for e = G.eStart.p[s - 1], G.eStart.p[s] - 1 do
    local j = G.edges.p[e]
    if G.flag[j] == 2 then wa = wa + 1
    elseif good[j] == 1 then sf = sf + 1
    elseif lost(S(j)) then vs = vs + 1
    else hd = hd + 1; regs[#regs+1] = region(j) end
  end
  line[#line+1] = string.format("%2d: безоп %d скрыт %d%s видим %d смыло %d", k - 1, sf, hd, #regs > 0 and ("(" .. table.concat(regs, ",") .. ")") or "", vs, wa)
end
print(table.concat(line, "\n"))
SV.freeGraph(G); require("ffi").C.free(good)
