-- build/l4v3/order.lua файл — достижима ли ошибка порядка в шахте (ниппель закреплён во входе раньше муфты на стояке)
package.path = "./?.lua;" .. package.path
local L = dofile("build/l4v3/lib.lua")
local A = L.load(arg[1])
local n, c = A.Q.nip, A.Q.cpl
local k, fixedC, firstFix = 0, 0, {}
for i = 1, A.G.n do if A.G.flag[i] ~= 2 then local st = A.sts[i]
  if st.fixed[n] and st.pos[n] == A.T and not (st.fixed[c] and st.pos[c] == A.B) then k = k + 1 end
  if st.fixed[c] and st.pos[c] == A.B then fixedC = fixedC + 1 end
end end
print(string.format("%s: состояний «ниппель во входе шахты, муфты на стояке нет» — %d; «муфта на стояке» — %d из %d", arg[1], k, fixedC, A.G.n))
-- где бывает свободный ниппель, пока муфта не на стояке (клетки нижнего яруса)
local cells = {}
for i = 1, A.G.n do if A.G.flag[i] ~= 2 then local st = A.sts[i]
  if not (st.fixed[c] and st.pos[c] == A.B) and st.pos[n] ~= 0 and not st.fixed[n] then local x, y = L.xy(A, st.pos[n]); if y >= 5 then cells[x .. "," .. y] = (cells[x .. "," .. y] or 0) + 1 end end
end end
local t = {}; for kk, v in pairs(cells) do t[#t + 1] = kk .. ":" .. v end; table.sort(t)
print("  свободный ниппель внизу, пока муфты нет на стояке: " .. (#t > 0 and table.concat(t, " ") or "нигде"))
