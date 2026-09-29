-- build/l4d/classes.lua файл.lua — состояния по классам конфигураций деталей (живые / скрытые / видимые), общая линейка.
-- Классы: где муфта и ниппель (закреплены на месте / не на месте / свободны), пара, порядок на полу относительно шахты.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local VL = V.compute(lvl, G, def, good)
local qc, qn, S
for q, p in ipairs(lvl.pieces) do
  if p.what == "coupling" then qc = q elseif p.movable then qn = q end
  if p.source then S = p.start end
end
local B = lvl.nb[S][1]; local T = lvl.nb[B][1]
local W = lvl.W
local function col(c) return (c - 1) % W + 1 end
local function row(c) return math.floor((c - 1) / W) + 1 end
local win = VL.win
local function desc(st, q)
  local c = st.pos[q]
  if c == 0 then return "смыт" end
  if st.fixed[q] then return c == win.pos[q] and "на месте" or ("прикручен не туда(" .. col(c) .. "," .. row(c) .. ")") end
  return "свободен"
end
local agg, liveMarked = {}, 0
for i = 1, G.n do
  if G.flag[i] ~= 2 then
    local st = VL.states[i]
    local k
    local pc, pn = st.pos[qc], st.pos[qn]
    if pc ~= 0 and pn ~= 0 and not st.fixed[qc] and not st.fixed[qn] and st.asm[qc] == st.asm[qn] then
      k = "ПАРА свободна (муфта снизу)"
    elseif pc ~= 0 and pn ~= 0 and not st.fixed[qc] and not st.fixed[qn] then
      local same = row(pc) == row(pn) and row(pc) == row(T)
      if same then
        local dc, dn = math.abs(col(T) - col(pc)), math.abs(col(T) - col(pn))
        k = (dn < dc) and "обе свободны на полу: ниппель ближе к шахте (порядок неверен)" or "обе свободны на полу: муфта ближе (порядок верен)"
      else
        k = "обе свободны, не в одном ряду с входом (ряды " .. row(pc) .. "/" .. row(pn) .. ")"
      end
    else
      k = "муфта " .. desc(st, qc) .. " | ниппель " .. desc(st, qn)
    end
    local a = agg[k] or { 0, 0, 0 }; agg[k] = a
    if good[i] == 1 then a[1] = a[1] + 1; if VL.newbie[i] then liveMarked = liveMarked + 1 end
    elseif VL.newbie[i] then a[3] = a[3] + 1 else a[2] = a[2] + 1 end
  end
end
local list = {}
for k, a in pairs(agg) do list[#list+1] = { k, a } end
table.sort(list, function(a, b) return a[2][1] + a[2][2] > b[2][1] + b[2][2] end)
print(string.format("%-75s %6s %8s %8s", "класс", "живых", "скрытых", "видимых"))
for _, e in ipairs(list) do print(string.format("%-75s %6d %8d %8d", e[1], e[2][1], e[2][2], e[2][3])) end
print("живых с пометкой видимого (должно быть 0): " .. liveMarked)
SV.freeGraph(G); require("ffi").C.free(good)
