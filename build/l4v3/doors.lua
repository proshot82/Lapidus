-- build/l4v3/doors.lua файл [разметка: a|ep|ef|epef] — двери живое→скрытое: с пути check, со всех кратчайших, по всему графу;
-- класс, расстояние от кратчайших путей, глубина области, минимум ходов до видимого проигрыша. Без ходов.
package.path = "./?.lua;" .. package.path
local L = dofile("build/l4v3/lib.lua")
local A = L.load(arg[1])
local cls = L.classes(A)
local mk = ({ a = {}, ep = { "EP" }, ef = { "EF" }, epef = { "EP", "EF" } })[arg[2] or "a"]
local M = L.mark(A, cls, mk)
local H = L.hiddenOf(A, M)
local G, good, sts = A.G, A.good, A.sts
local ES, E = G.eStart.p, G.edges.p
print(string.format("%s, разметка %s; ходов %d, состояний на кратчайших путях %d", arg[1], arg[2] or "a", A.opt, (function() local n = 0 for _ in pairs(A.onSP) do n = n + 1 end return n end)()))
-- расстояние (по живым) от кратчайших путей
local dSP, q, h = {}, {}, 1
for i in pairs(A.onSP) do dSP[i] = 0; q[#q + 1] = i end
while h <= #q do local i = q[h]; h = h + 1
  for e = ES[i - 1], ES[i] - 1 do local j = E[e]; if good[j] == 1 and dSP[j] == nil then dSP[j] = dSP[i] + 1; q[#q + 1] = j end end end
local byCls = {}
for i = 1, G.n do if G.flag[i] ~= 2 and good[i] == 1 then
  for e = ES[i - 1], ES[i] - 1 do local j = E[e]
    if H[j] then
      local k = L.classOf(A, cls, sts[j])
      local t = byCls[k] or { n = 0, minD = 1e9, deep = 0, reveal = {}, steps = {} }; byCls[k] = t
      t.n = t.n + 1
      if dSP[i] and dSP[i] < t.minD then t.minD = dSP[i] end
      local d, sz = L.depthFrom(A, H, j)
      if d > t.deep then t.deep = d end
      t.reveal[#t.reveal + 1] = L.toVisible(A, M, j) or -1
      if A.onSP[i] then t.steps[G.depth[i]] = (t.steps[G.depth[i]] or 0) + 1 end
    end
  end
end end
for k, t in pairs(byCls) do
  table.sort(t.reveal)
  local st = {}
  for s = 0, A.opt do if t.steps[s] then st[#st + 1] = s .. "×" .. t.steps[s] end end
  print(string.format("  %s %-50s дверей %3d | ближайшая к кратчайшим в %s ходах | с кратчайших на шагах: %s | глубина до %d | до видимого min %d, медиана %d, max %d",
    cls[k][1], cls[k][2], t.n, t.minD == 1e9 and "∞" or tostring(t.minD), #st > 0 and table.concat(st, " ") or "—", t.deep,
    t.reveal[1], t.reveal[math.ceil(#t.reveal / 2)], t.reveal[#t.reveal]))
end
-- различные раскладки деталей сразу после ошибки с кратчайших путей
local errs = {}
for _, d in ipairs(L.doors(A, H, false)) do local k = L.cfg(A, sts[d.to]); errs[k] = (errs[k] or 0) + 1 end
local ne = 0; for _ in pairs(errs) do ne = ne + 1 end
print("  различных раскладок деталей сразу после ошибки с кратчайших путей: " .. ne)
-- рёбра путь→скрытое, где раскладка деталей НЕ меняется (ошибка — ход Лапидуса, а не детали)
local lap = 0
for _, d in ipairs(L.doors(A, H, false)) do if L.cfg(A, sts[d.from]) == L.cfg(A, sts[d.to]) then lap = lap + 1 end end
print("  из них дверей без сдвига деталей (ошибка — поза Лапидуса): " .. lap)
