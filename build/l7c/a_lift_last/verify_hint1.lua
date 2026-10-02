-- verify_hint1.lua файл.lua [сетки] — скептик кв. 7 (28.09): ошибки «против подсказки №1» конкретными состояниями.
-- Для каждого класса ошибки: переходы из живых состояний, сколько разных мёртвых состояний они дают, самое раннее
-- (по глубине от старта), как его помечает каждая разметка (narrow / wideA / V1 / V2 / V3) и сколько ходов из него
-- можно блуждать по скрытым (для V2) до видимого проигрыша. С аргументом «сетки» печатает сетку самого раннего
-- мёртвого состояния каждого класса (только вывод инструмента; это не решение и не путь).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = dofile("build/l7c/a_lift_last/verify_vis.lua")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local Q = {}
for q, p in ipairs(lvl.pieces) do if p.tag then Q[p.tag] = q end end
local S = {}
local function st(i) if not S[i] then S[i] = R.decode(lvl, G.keys[i]) end return S[i] end
local I = function(x, y) return R.idx(lvl, x, y) end
local function col6low(c) if c == 0 then return false end local xx, yy = R.xy(lvl, c); return xx == 6 and yy >= 5 end
local ERR = {
  { "E1 фонтан заглушён раньше переходника", function(a, b) return not a.fixed[Q.elb] and b.fixed[Q.elb] and not b.fixed[Q.adp] end },
  { "E3 муфта скормлена фонтану раньше переходника (зажата в шахте)", function(a, b) return not col6low(a.pos[Q.cpl]) and col6low(b.pos[Q.cpl]) and not b.fixed[Q.adp] and not b.fixed[Q.cpl] end },
  { "E4 муфта вкручена в ванну (заткнуть течь муфтой / скормить раньше)", function(a, b) return not a.fixed[Q.cpl] and b.fixed[Q.cpl] end },
  { "E5 муфта отложена в угол кармана", function(a, b) return a.pos[Q.cpl] ~= I(8, 6) and b.pos[Q.cpl] == I(8, 6) end },
}
local marks = { "narrow", "wideA", "V1", "V2", "V3" }
local function lostBy(nm, s)
  for q, p in ipairs(lvl.pieces) do if p.movable and s.pos[q] == 0 then return true end end
  return V[nm](lvl, s)
end
local function wander(j, nm)
  local d, q, h, maxd = { [j] = 0 }, { j }, 1, 0
  while h <= #q do
    local u = q[h]; h = h + 1
    for e = G.eStart.p[u - 1], G.eStart.p[u] - 1 do
      local v = G.edges.p[e]
      if d[v] == nil and G.flag[v] ~= 2 and good[v] ~= 1 and not lostBy(nm, st(v)) then d[v] = d[u] + 1; if d[v] > maxd then maxd = d[v] end; q[#q + 1] = v end
    end
  end
  return maxd
end
local SYM = { source = "S", fixture = "F", fitting = "b" }
local JS = { "^", ">", "v", "<" }
local function show(s)
  local rows = {}
  for y = 1, lvl.H do rows[y] = {} for x = 1, lvl.W do local c = lvl.cell[(y-1)*lvl.W+x]; rows[y][x] = c == 1 and "#" or (c == 2 and "~" or ".") end end
  for _, j in ipairs(R.jets(lvl, s)) do for _, c in ipairs(j.cells) do local x, y = R.xy(lvl, c); rows[y][x] = JS[j.dir] end end
  for q, pp in ipairs(lvl.pieces) do if s.pos[q] ~= 0 then local x, y = R.xy(lvl, s.pos[q]); local ch = (pp.tag and pp.tag:sub(1,1)) or SYM[pp.kind]; if pp.movable then ch = s.fixed[q] and ch:upper() or ch:lower() else ch = SYM[pp.kind] end; rows[y][x] = ch end end
  for i, c in ipairs(s.body) do local x, y = R.xy(lvl, c); rows[y][x] = (i == #s.body) and "H" or ((i == 1) and "f" or "o") end
  for y = 1, lvl.H do print("      " .. table.concat(rows[y])) end
end
for _, E in ipairs(ERR) do
  local n, targets, first = 0, {}, nil
  local cnt = {}
  for _, nm in ipairs(marks) do cnt[nm] = 0 end
  local liveT = 0
  for i = 1, G.n do
    if good[i] == 1 and G.flag[i] == 0 then
      for e = G.eStart.p[i - 1], G.eStart.p[i] - 1 do
        local j = G.edges.p[e]
        if G.flag[j] ~= 2 and E[2](st(i), st(j)) then
          n = n + 1
          if good[j] == 1 then liveT = liveT + 1 else
            if not targets[j] then
              targets[j] = true
              for _, nm in ipairs(marks) do if not lostBy(nm, st(j)) then cnt[nm] = cnt[nm] + 1 end end
              if not first or G.depth[j] < G.depth[first] then first = j end
            end
          end
        end
      end
    end
  end
  local nt = 0
  for _ in pairs(targets) do nt = nt + 1 end
  local t = {}
  for _, nm in ipairs(marks) do t[#t + 1] = nm .. " " .. cnt[nm] end
  print(string.format("%s: переходов из живых %d (в живые %d); разных мёртвых состояний %d; из них СКРЫТЫХ по разметкам: %s",
    E[1], n, liveT, nt, table.concat(t, ", ")))
  if first then
    local fl = {}
    for _, nm in ipairs(marks) do fl[#fl + 1] = nm .. ":" .. (lostBy(nm, st(first)) and "вид" or "СКР") end
    print(string.format("    самое раннее мёртвое на глубине %d: живо ли — %s; %s; блуждание по скрытым (V2) — %d ходов",
      G.depth[first], good[first] == 1 and "да" or "нет", table.concat(fl, " "), wander(first, "V2")))
    if arg[2] == "сетки" then show(st(first)) end
  end
end
SV.freeGraph(G); require("ffi").C.free(good)
