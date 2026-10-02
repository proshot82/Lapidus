-- verify_show.lua файл.lua "условие" [сколько] [все] — скептик кв. 7: примеры МЁРТВЫХ СКРЫТЫХ состояний с условием
-- (сетка одного состояния, без пути к нему; только вывод инструмента). С «все» — и живые, и видимые (помечены).
-- Условие — выражение Lua от st, fx(тег), at(тег,x,y), xy(тег) → x,y, L(x,y), cap (фонтан заглушён), pair.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local Q = {}
for q, p in ipairs(lvl.pieces) do if p.tag then Q[p.tag] = q end end
local cond = assert(load("return function(st, fx, at, xy, L, cap, pair) return " .. arg[2] .. " end"))()
local maxn = tonumber(arg[3] or 6)
local all = arg[4] == "все"
local function lost(st)
  for q, p in ipairs(lvl.pieces) do if p.movable and st.pos[q] == 0 then return true end end
  return def.visibleLoss and def.visibleLoss(lvl, st) or false
end
local SYM = { source = "S", fixture = "F", stub = "T", pipe = "=", fitting = "b", porcelain = "P" }
local JS = { "^", ">", "v", "<" }
local function show(s, label)
  local rows = {}
  for y = 1, lvl.H do rows[y] = {} for x = 1, lvl.W do local c = lvl.cell[(y-1)*lvl.W+x]; rows[y][x] = c == 1 and "#" or (c == 2 and "~" or ".") end end
  if not s.dead then for _, j in ipairs(R.jets(lvl, s)) do for _, c in ipairs(j.cells) do local x, y = R.xy(lvl, c); rows[y][x] = JS[j.dir] end end end
  for q, pp in ipairs(lvl.pieces) do if s.pos[q] ~= 0 then local x, y = R.xy(lvl, s.pos[q]); local ch = (pp.tag and pp.tag:sub(1,1)) or SYM[pp.kind]; if pp.movable then ch = s.fixed[q] and ch:upper() or ch:lower() else ch = SYM[pp.kind] end; rows[y][x] = ch end end
  if not s.dead then for i, c in ipairs(s.body) do local x, y = R.xy(lvl, c); rows[y][x] = (i == #s.body) and "H" or ((i == 1) and "f" or "o") end end
  local out = { label }
  for y = 1, lvl.H do out[#out+1] = table.concat(rows[y]) end
  return out
end
local picked, total = {}, 0
local cnt = { live = 0, hid = 0, vis = 0 }
for i = 1, G.n do
  if G.flag[i] ~= 2 then
    local st = R.decode(lvl, G.keys[i])
    local function fx(t) return st.fixed[Q[t]] end
    local function at(t, x, y) return st.pos[Q[t]] == R.idx(lvl, x, y) end
    local function xy(t) if st.pos[Q[t]] == 0 then return 0, 0 end return R.xy(lvl, st.pos[Q[t]]) end
    local function L(x, y) local c = R.idx(lvl, x, y); for _, b in ipairs(st.body) do if b == c then return true end end return false end
    local cap = st.fixed[Q.elb]
    local pair = st.pos[Q.adp] ~= 0 and st.pos[Q.cpl] ~= 0 and st.asm[Q.adp] == st.asm[Q.cpl]
    if cond(st, fx, at, xy, L, cap, pair) then
      local kind = good[i] == 1 and "live" or (lost(st) and "vis" or "hid")
      cnt[kind] = cnt[kind] + 1
      if all or kind == "hid" then picked[#picked + 1] = { i = i, kind = kind } end
    end
  end
end
print(string.format("условие: живых %d, скрытых %d, видимых %d", cnt.live, cnt.hid, cnt.vis))
table.sort(picked, function(a, b) return G.depth[a.i] < G.depth[b.i] end)
local frames = {}
local step = math.max(1, math.floor(#picked / maxn))
for k = 1, #picked, step do
  if #frames >= maxn then break end
  local p = picked[k]
  frames[#frames + 1] = show(R.decode(lvl, G.keys[p.i]), string.format("%s d%d", p.kind, G.depth[p.i]))
end
local per = math.max(1, math.floor(130 / (lvl.W + 2)))
for k = 1, #frames, per do
  for line = 1, #frames[k] do
    local parts = {}
    for j = k, math.min(k + per - 1, #frames) do parts[#parts+1] = string.format("%-" .. (lvl.W + 2) .. "s", frames[j][line] or "") end
    print(table.concat(parts, ""))
  end
  print()
end
SV.freeGraph(G); require("ffi").C.free(good)
