-- build/l7v_g/an.lua файл.lua — слепой скептик кв. 7: порог кармана 3..6, классы скрытых, входы с пути.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local function cfg(s)
  local t = {}
  for q, p in ipairs(lvl.pieces) do if p.movable then
    if s.pos[q] == 0 then t[#t+1] = p.tag .. "=смыт" else
    local x, y = R.xy(lvl, s.pos[q]); t[#t+1] = string.format("%s(%d,%d)%s%s", p.tag, x, y, s.fixed[q] and "F" or "", "a"..s.asm[q]) end end end
  return table.concat(t, " ")
end
local sts = {}
for i = 1, G.n do if G.flag[i] ~= 2 then sts[i] = R.decode(lvl, G.keys[i]) end end
local res = {}
for _, P in ipairs({ 3, 4, 5, 6, 8, 12 }) do
  V.POCKET = P
  local VL = V.compute(lvl, G, def, good)
  local m = V.measure(G, good, VL.newbie)
  local e = V.measure(G, good, VL.expert)
  res[P] = { VL = VL, m = m, e = e }
  print(string.format("POCKET %2d: новичок скрытых %d (%.1f %%) обезьяна %.3f глубина %d [%s] | знаток скрытых %d (%.1f %%) глуб %d [%s] | counts frozen %d",
    P, m.hid, m.hiddenPct, m.smart, m.maxDeep, m.deepList, e.hid, e.hiddenPct, e.maxDeep, e.deepList, VL.counts.frozen))
end
V.POCKET = 4
-- скачки: что становится видимым при переходе
local function diff(a, b)
  local agg = {}
  for i = 1, G.n do
    if sts[i] and good[i] ~= 1 and (res[a].VL.newbie[i] ~= res[b].VL.newbie[i]) then
      local k = cfg(sts[i]) .. (res[b].VL.newbie[i] and " -> ВИДИМ" or " -> СКРЫТ")
      agg[k] = (agg[k] or 0) + 1
    end
  end
  local l = {}
  for k, v in pairs(agg) do l[#l+1] = { k, v } end
  table.sort(l, function(x, y) return x[2] > y[2] end)
  print(string.format("== переход POCKET %d -> %d: классов %d", a, b, #l))
  for i = 1, math.min(15, #l) do print(string.format("  %6d  %s", l[i][2], l[i][1])) end
end
diff(3, 4); diff(4, 5); diff(5, 6); diff(6, 8); diff(8, 12)
-- классы скрытых при POCKET 4
local agg = {}
local hid = res[4].m.hidden
for i in pairs(hid) do local k = cfg(sts[i]); agg[k] = (agg[k] or 0) + 1 end
local l = {}
for k, v in pairs(agg) do l[#l+1] = { k, v } end
table.sort(l, function(x, y) return x[2] > y[2] end)
print("== скрытые (POCKET 4) по конфигурации деталей, классов " .. #l)
for i = 1, math.min(40, #l) do print(string.format("  %6d  %s%s", l[i][2], l[i][1], "")) end
-- входы в скрытые с кратчайшего пути
local path = res[4].m.path
print("== входы в скрытое с пути (новичок)")
for k = 1, #path - 1 do
  local s = path[k]
  for e = G.eStart.p[s - 1], G.eStart.p[s] - 1 do
    local j = G.edges.p[e]
    if hid[j] then print(string.format("  шаг %d: %s  [%s]", k - 1, cfg(sts[j]), R.moveName(G.pmove[j]))) end
  end
end
SV.freeGraph(G); require("ffi").C.free(good)
