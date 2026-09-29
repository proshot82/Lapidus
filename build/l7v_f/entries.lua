-- build/l7v_f/entries.lua файл.lua — входы живое→скрытое: с любого кратчайшего пути (по фазам) и «ошибки подсказки №1»
-- (переход, после которого Лапидус держит собой фонтан или деталь в столбе). Печать — только в терминал.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
V.POCKET = tonumber(arg[2] or 4)
local VL = V.compute(lvl, G, def, good)
local ES, E, flag = G.eStart.p, G.edges.p, G.flag
local n = G.n
local sts = {}
local function S(i) sts[i] = sts[i] or R.decode(lvl, G.keys[i]); return sts[i] end
local function cfg(s)
  local t = {}
  for q, p in ipairs(lvl.pieces) do if p.movable then
    if s.pos[q] == 0 then t[#t+1] = p.tag .. "=смыт" else
    local x, y = R.xy(lvl, s.pos[q]); t[#t+1] = string.format("%s(%d,%d)%s%s", p.tag, x, y, s.fixed[q] and "F" or "", "a"..s.asm[q]) end end end
  return table.concat(t, " ")
end
-- расстояние до победы (обратный BFS)
local rs, rv = {}, {}
local cnt = {}
for i = 1, n + 1 do cnt[i] = 0 end
for i = 1, n do for e = ES[i-1], ES[i]-1 do local j = E[e]; cnt[j] = cnt[j] + 1 end end
local st, s = {}, 1
for i = 1, n do st[i] = s; s = s + cnt[i] end
st[n+1] = s
local fill = {}
for i = 1, n do fill[i] = st[i] end
for i = 1, n do for e = ES[i-1], ES[i]-1 do local j = E[e]; rv[fill[j]] = i; fill[j] = fill[j] + 1 end end
local dw, q, h = {}, {}, 1
for i = 1, n do if flag[i] == 1 then dw[i] = 0; q[#q+1] = i end end
while h <= #q do local j = q[h]; h = h + 1; for k = st[j], st[j+1]-1 do local i = rv[k]; if dw[i] == nil then dw[i] = dw[j] + 1; q[#q+1] = i end end end
local opt = G.depth[G.firstWin]
local hidden = function(j) return flag[j] == 0 and good[j] ~= 1 and not VL.newbie[j] end
local hiddenE = function(j) return flag[j] == 0 and good[j] ~= 1 and not VL.expert[j] end
local function region(j, hf)
  local d, qq, hh, maxd = { [j] = 0 }, { j }, 1, 0
  while hh <= #qq do local u = qq[hh]; hh = hh + 1
    for e = ES[u-1], ES[u]-1 do local v = E[e]; if hf(v) and d[v] == nil then d[v] = d[u] + 1; if d[v] > maxd then maxd = d[v] end; qq[#qq+1] = v end end end
  return maxd, #qq
end
-- 1) все состояния на кратчайших путях: входы в скрытое (новичок/знаток) и в видимое, по фазе (глубина)
print("== кратчайшие: фаза | ходов в живое | в скрытое(новичок) | в скрытое(знаток) | в видимое | смыло")
for i = 1, n do
  if G.depth[i] and dw[i] and G.depth[i] + dw[i] == opt and flag[i] == 0 then
    local a, b, c, d, w = 0, 0, 0, 0, 0
    local notes = {}
    for e = ES[i-1], ES[i]-1 do local j = E[e]
      if flag[j] == 2 then w = w + 1 elseif good[j] == 1 then a = a + 1
      elseif hidden(j) then b = b + 1; local md, sz = region(j, hidden); notes[#notes+1] = string.format("скр гл%d/%d %s", md, sz, cfg(S(j)))
        if hiddenE(j) then c = c + 1 end
      else d = d + 1 end
    end
    print(string.format("  ш%2d  жив %d  скрН %d  скрЗ %d  вид %d  смыло %d  %s", G.depth[i], a, b, c, d, w, table.concat(notes, " ; ")))
  end
end
-- 2) ошибки «подсказки №1»: переход из живого в мёртвое, после которого Лапидус держит собой фонтан
local col = {}
local function fountain(ns)
  local c = {}
  for _, j in ipairs(R.jets(lvl, ns)) do if j.dir == R.UP and not j.lapidus then for _, x in ipairs(j.cells) do c[x] = true end end end
  return c
end
local agg = {}
for i = 1, n do
  if flag[i] == 0 and good[i] == 1 then
    for e = ES[i-1], ES[i]-1 do local j = E[e]
      if flag[j] == 0 and good[j] ~= 1 then
        local s2 = S(j); local c = fountain(s2); local plug = false
        for _, b in ipairs(s2.body) do if c[b] then plug = true end end
        local hold = false
        local body = {}; for _, b in ipairs(s2.body) do body[b] = true end
        for qq, p in ipairs(lvl.pieces) do local x = s2.pos[qq]; if p.movable and x ~= 0 and not s2.fixed[qq] and c[x] and body[lvl.nb[x][1]] then hold = true end end
        if plug or hold then
          local k = (hidden(j) and "СКРЫТ " or "видим ") .. (hold and "держит деталь " or "затыкает собой ") .. cfg(s2)
          local a = agg[k] or { n = 0, deep = 0, sp = false }; agg[k] = a
          a.n = a.n + 1
          if hidden(j) then local md = region(j, hidden); if md > a.deep then a.deep = md end end
          if G.depth[i] + dw[i] == opt then a.sp = true end
        end
      end
    end
  end
end
print("== ошибки «подсказки №1» (живое → мёртвое, Лапидус затыкает фонтан собой)")
for k, a in pairs(agg) do print(string.format("  %4d входов, скрытая глубина %2d, с кратчайшего %s: %s", a.n, a.deep, a.sp and "ДА" or "нет", k)) end
SV.freeGraph(G); require("ffi").C.free(good)
