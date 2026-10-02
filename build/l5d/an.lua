-- build/l5d/an.lua файл.lua [frames] — разбор кандидата кв. 5 по воротам 30.09 (общая линейка tools/vislib.lua, карман 4).
-- Печатает: двери с КРАТЧАЙШИХ путей (все кратчайшие), по шагу — класс входа, через сколько ходов проигрыш можно
-- увидеть (минимум), глубина и размер скрытой области; классы скрытых состояний по раскладке деталей.
-- Кадры (frames) — только в выводе инструмента, в отчёты не переносить.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local def = dofile(arg[1])
V.POCKET = tonumber(os.getenv("POCKET") or 4)
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
if not G.firstWin then print("НЕРЕШАЕМ n=" .. G.n) return end
local good = SV.goodSet(G)
local VL = V.compute(lvl, G, def, good)
local m = V.measure(G, good, VL.newbie)
local ES, E, flag, n = G.eStart.p, G.edges.p, G.flag, G.n
local function cfg(s)
  local t = {}
  for q, p in ipairs(lvl.pieces) do if p.movable then
    if s.pos[q] == 0 then t[#t+1] = (p.tag or p.what) .. "=смыт" else
    local x, y = R.xy(lvl, s.pos[q]); t[#t+1] = string.format("%s(%d,%d)%s", p.tag or p.what, x, y, s.fixed[q] and "F" or (s.asm[q] ~= q and "+" or "")) end end end
  return table.concat(t, " ")
end
-- расстояние до победы
local cnt = {}; for i = 1, n + 1 do cnt[i] = 0 end
for i = 1, n do for e = ES[i-1], ES[i]-1 do local j = E[e]; cnt[j] = cnt[j] + 1 end end
local st, s = {}, 1; for i = 1, n do st[i] = s; s = s + cnt[i] end; st[n+1] = s
local fill, rv = {}, {}; for i = 1, n do fill[i] = st[i] end
for i = 1, n do for e = ES[i-1], ES[i]-1 do local j = E[e]; rv[fill[j]] = i; fill[j] = fill[j] + 1 end end
local dw, q, h = {}, {}, 1
for i = 1, n do if flag[i] == 1 then dw[i] = 0; q[#q+1] = i end end
while h <= #q do local j = q[h]; h = h + 1; for k = st[j], st[j+1]-1 do local i = rv[k]; if dw[i] == nil then dw[i] = dw[j] + 1; q[#q+1] = i end end end
local opt = m.opt
local function hid(j) return m.hidden[j] end
local function area(j)
  local d, qx, hx, rev, maxd = { [j] = 0 }, { j }, 1, nil, 0
  while hx <= #qx do local u = qx[hx]; hx = hx + 1
    for ee = ES[u-1], ES[u]-1 do local v = E[ee]
      if flag[v] == 0 and good[v] ~= 1 and VL.newbie[v] and not rev then rev = d[u] + 1 end
      if hid(v) and d[v] == nil then d[v] = d[u] + 1; if d[v] > maxd then maxd = d[v] end; qx[#qx+1] = v end end end
  return rev or 99, maxd, #qx
end
local rows = {}
for i = 1, n do if flag[i] == 0 and good[i] == 1 and dw[i] and G.depth[i] + dw[i] == opt then
  for e = ES[i-1], ES[i]-1 do local j = E[e]
    if hid(j) then
      local key = G.depth[i] .. "|" .. cfg(VL.states[j])
      local r = rows[key]
      if not r then local rev, dp, sz = area(j); r = { k = G.depth[i], c = cfg(VL.states[i]) .. " → " .. cfg(VL.states[j]), rev = rev, dp = dp, sz = sz, n = 0 }; rows[key] = r end
      r.n = r.n + 1
    end end end end
local l = {}
for _, r in pairs(rows) do l[#l+1] = r end
table.sort(l, function(a, b) if a.k ~= b.k then return a.k < b.k end return a.c < b.c end)
print(string.format("ходов %d | состояний %d | скрытых %.1f %% (жив %d скр %d вид %d) | обезьяна %.3f %% | знаток %.1f %%",
  opt, n, m.hiddenPct, m.live, m.hid, m.vis, m.smart, V.measure(G, good, VL.expert).hiddenPct))
print("ДВЕРИ с кратчайших путей: шаг/" .. opt .. " | вскрытие (мин ходов до видимого) | глубина | область | переход")
for _, r in ipairs(l) do print(string.format("  шаг %2d %s вскр %2s гл %2d обл %4d  %s", r.k, r.k < opt / 2 and "1п" or "2п", r.rev == 99 and "∞" or tostring(r.rev), r.dp, r.sz, r.c)) end
-- классы скрытых
local agg = {}
for i = 1, n do if hid(i) then local k = cfg(VL.states[i]); agg[k] = (agg[k] or 0) + 1 end end
local cl = {}
for k, c in pairs(agg) do cl[#cl+1] = { k, c } end
table.sort(cl, function(a, b) return a[2] > b[2] end)
print("классы скрытых:")
for i = 1, math.min(tonumber(os.getenv("NCLS") or 12), #cl) do print(string.format("  %5d  %s", cl[i][2], cl[i][1])) end
if arg[2] == "frames" then
  local path, x = {}, G.firstWin
  while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
  table.insert(path, 1, 1)
  local SYM = { source = "S", fixture = "F", stub = "T", pipe = "=", fitting = "b", porcelain = "P" }
  local frames = {}
  for k, id in ipairs(path) do
    local s2 = VL.states[id]
    local rows2 = {}
    for y = 1, lvl.H do rows2[y] = {} for xx = 1, lvl.W do local c = lvl.cell[(y-1)*lvl.W+xx]; rows2[y][xx] = c == 1 and "#" or (c == 2 and "~" or ".") end end
    for qq, pp in ipairs(lvl.pieces) do if s2.pos[qq] ~= 0 then local xx, y = R.xy(lvl, s2.pos[qq]); local ch = (pp.tag or pp.what or pp.kind):sub(1,1); if not pp.movable then ch = SYM[pp.kind] elseif s2.fixed[qq] then ch = ch:upper() end; rows2[y][xx] = ch end end
    for bi, c in ipairs(s2.body) do local xx, y = R.xy(lvl, c); rows2[y][xx] = (bi == #s2.body) and "H" or ((bi == 1) and "f" or "o") end
    local out = { tostring(k - 1) }
    for y = 1, lvl.H do out[#out+1] = table.concat(rows2[y]) end
    frames[#frames+1] = out
  end
  local per = math.max(1, math.floor(120 / (lvl.W + 2)))
  for k = 1, #frames, per do
    for line = 1, #frames[k] do
      local parts = {}
      for j = k, math.min(k + per - 1, #frames) do parts[#parts+1] = string.format("%-" .. (lvl.W + 2) .. "s", frames[j][line] or "") end
      print(table.concat(parts, ""))
    end
  end
end
SV.freeGraph(G); require("ffi").C.free(good)
