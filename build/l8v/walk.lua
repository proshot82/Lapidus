-- build/l8v/walk.lua файл.lua — скептик кв. 8: «прогулка» с учётом событий самого Лапидуса.
-- По кратчайшему пути каждый шаг помечается: Д — сдвиг детали, Я — смена якорей (прикрутился/открутился),
-- С — струя сдвинула тело Лапидуса при устаканивании, · — ничего. Печатает строку меток и максимальные
-- серии без событий: только по деталям (как в check.lua) и по всем событиям. Ходы не печатаются.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
assert(G and G.firstWin, "нерешаем")
local path, x = {}, G.firstWin
while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
table.insert(path, 1, 1)
local function objs(st) local t = {}; for q = 1, #st.pos do t[#t+1] = st.pos[q] .. (st.fixed[q] and "f" or "") end; return table.concat(t, ",") end
local function anch(st) local w = R.water(lvl, st); return tostring(w.headQ) .. "/" .. tostring(w.heelQ) end
local marks, sD, sA, mD, mA = {}, 0, 0, 0, 0
for i = 1, #path - 1 do
  local s0, s1 = R.decode(lvl, G.keys[path[i]]), R.decode(lvl, G.keys[path[i + 1]])
  local mv = R.MOVES[G.pmove[path[i + 1]]]
  local trace = {}
  R.move(lvl, s0, mv.which, mv.dir, trace)
  local pushed = false
  for k = 2, #trace do
    local a, b = trace[k - 1].state.body, trace[k].state.body
    if #a == #b then for j = 1, #a do if a[j] ~= b[j] then pushed = true end end end
  end
  local m = ""
  if objs(s0) ~= objs(s1) then m = m .. "Д" end
  if anch(s0) ~= anch(s1) then m = m .. "Я" end
  if pushed then m = m .. "С" end
  if m == "" then m = "·" end
  marks[#marks + 1] = m
  if objs(s0) ~= objs(s1) then sD = 0 else sD = sD + 1; if sD > mD then mD = sD end end
  if m == "·" then sA = sA + 1; if sA > mA then mA = sA end else sA = 0 end
end
print("шаги: " .. table.concat(marks, " "))
print(string.format("прогулка по деталям (как в check.lua): %d | по всем событиям (деталь, якорь, струя сдвинула тело): %d", mD, mA))
SV.freeGraph(G)
