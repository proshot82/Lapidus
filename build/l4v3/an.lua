-- build/l4v3/an.lua файл [POCKET] — правила visibleLoss, классы скрытых, разметки, двери по классам (без ходов).
package.path = "./?.lua;" .. package.path
local L = dofile("build/l4v3/lib.lua")
local file = arg[1]
local A = L.load(file, { pocket = tonumber(arg[2] or "") })
local G, good, sts, lvl, V = A.G, A.good, A.sts, A.lvl, A.V
local cls = L.classes(A)
local base = V.measure(G, good, A.VL.newbie)
print(string.format("%s POCKET=%d: ходов %d | состояний %d | живых %d видимых %d скрытых %d | СКРЫТЫХ %.1f %% | обезьяна %.3f %% | глубина %d [%s]",
  file, V.POCKET, base.opt, G.n, base.live, base.vis, base.hid, base.hiddenPct, base.smart, base.maxDeep, base.deepList))
local m0 = V.measure(G, good, A.VL0.newbie)
print(string.format("только общая линейка: скрытых %.1f %% | глубина %d [%s]", m0.hiddenPct, m0.maxDeep, m0.deepList))
local ex = V.measure(G, good, A.VL.expert)
print(string.format("знаток: скрытых %.1f %% | глубина %d [%s]", ex.hiddenPct, ex.maxDeep, ex.deepList))
print("счёт общей линейки (newbie): frozen " .. A.VL.counts.frozen .. ", levelRule " .. A.VL.counts.levelRule .. ", washed " .. A.VL.counts.washed)

-- правила уровня по отдельности (повтор логики файла уровня с номером правила)
local OPP = { 3, 4, 1, 2 }
local function ruleId(st)
  local atB, atT = false, false
  local occ = {}
  for q, p in ipairs(lvl.pieces) do
    if st.pos[q] ~= 0 then occ[st.pos[q]] = q end
    if p.movable then
      if st.pos[q] == 0 then return "r0 смыто" end
      if st.pos[q] == A.B and st.fixed[q] then atB = true end
      if st.pos[q] == A.T and st.fixed[q] then atT = true end
    end
  end
  if atT and not atB then return "r1 вход шахты закрыт" end
  for q, p in ipairs(lvl.pieces) do
    if p.movable and st.fixed[q] then
      for d = 1, 4 do local th = p.ports[d]
        if th then
          local t = lvl.nb[st.pos[q]][d]
          if t == 0 or lvl.cell[t] == 1 then return "r2a резьба в стену" end
          local r = occ[t]
          if r and st.fixed[r] then
            local th2 = lvl.pieces[r].ports[OPP[d]]
            if th2 == nil then return "r2b в глухой бок" end
            if th2 == th then return "r2c в такую же резьбу" end
          end
        end
      end
    end
  end
  return nil
end
local rs, order = {}, {}
for i = 1, G.n do if G.flag[i] ~= 2 then
  local r = ruleId(sts[i])
  assert((r ~= nil) == (A.def.visibleLoss(lvl, sts[i]) and true or false), "ruleId mismatch")
  if r then
    if not rs[r] then rs[r] = { 0, 0, 0 }; order[#order + 1] = r end
    local t = rs[r]; t[1] = t[1] + 1
    if good[i] == 1 then t[2] = t[2] + 1 end
    if not A.VL0.newbie[i] then t[3] = t[3] + 1 end
  end
end end
-- «сужение»: есть ли состояние, помеченное общей линейкой, но не итоговой разметкой
local narrowed = 0
for i = 1, G.n do if G.flag[i] ~= 2 and A.VL0.newbie[i] and not A.VL.newbie[i] then narrowed = narrowed + 1 end end
print("правило: срабатываний / живых / сверх общей линейки;  сужений линейки: " .. narrowed)
table.sort(order)
for _, r in ipairs(order) do print(string.format("  %-26s %6d %6d %6d", r, rs[r][1], rs[r][2], rs[r][3])) end

-- классы скрытых
local H = L.hiddenOf(A, A.VL.newbie)
local hc, htot = {}, 0
local allc = {}
for i = 1, G.n do if G.flag[i] ~= 2 then
  local k = L.classOf(A, cls, sts[i])
  allc[k] = allc[k] or { 0, 0, 0 }
  if good[i] == 1 then allc[k][1] = allc[k][1] + 1 elseif H[i] then allc[k][2] = allc[k][2] + 1 else allc[k][3] = allc[k][3] + 1 end
  if H[i] then hc[k] = (hc[k] or 0) + 1; htot = htot + 1 end
end end
-- двери живое -> скрытое по классам, со всех кратчайших и с пути check.lua
local doorsAll, doorsSP, doorsPath = {}, {}, {}
local ES, E = G.eStart.p, G.edges.p
for i = 1, G.n do if G.flag[i] ~= 2 and good[i] == 1 then
  for e = ES[i - 1], ES[i] - 1 do local j = E[e]
    if H[j] then local k = L.classOf(A, cls, sts[j]); doorsAll[k] = (doorsAll[k] or 0) + 1
      if A.onSP[i] then doorsSP[k] = (doorsSP[k] or 0) + 1 end end end end end
for _, d in ipairs(L.doors(A, H, true)) do local k = L.classOf(A, cls, sts[d.to]); doorsPath[k] = (doorsPath[k] and (doorsPath[k] .. ",") or "") .. d.step end
print(string.format("классы скрытых (всего %d); колонки: скрытых, %% | всего в классе живых/скрытых/видимых | двери: все / с кратчайших / шаги пути check", htot))
for k, c in ipairs(cls) do
  local a = allc[k] or { 0, 0, 0 }
  print(string.format("  %s %-58s %5d %5.1f %% | %5d/%5d/%5d | %3d / %2d / %s", c[1], c[2], hc[k] or 0, 100 * (hc[k] or 0) / math.max(1, htot),
    a[1], a[2], a[3], doorsAll[k] or 0, doorsSP[k] or 0, doorsPath[k] or "-"))
end
-- живые клетки свободного угольника внизу
local lowLive = {}
for c in pairs(A.liveFree.elb) do local x, y = L.xy(A, c); if y >= 5 then lowLive[#lowLive + 1] = x .. "," .. y end end
print("свободный угольник внизу живым бывает в клетках: " .. (#lowLive > 0 and table.concat(lowLive, " ") or "нигде"))
-- разметки
local marks = {
  { "автор (линейка + visibleLoss)", {} },
  { "+ EP видим (порт занят)", { "EP" } },
  { "+ EF видим (угольник внизу — нечем поднять)", { "EF" } },
  { "+ EP + EF", { "EP", "EF" } },
  { "+ EP + EF + CD", { "EP", "EF", "CD" } },
  { "+ EP + EF + PR", { "EP", "EF", "PR" } },
  { "+ NW видим (для сравнения)", { "NW" } },
  { "+ OR видим (для сравнения)", { "OR" } },
}
print("разметка → скрытых % | обезьяна | глубина [у пути] | двери с пути check по шагам")
for _, mk in ipairs(marks) do
  local M = L.mark(A, cls, mk[2])
  local m = V.measure(G, good, M)
  local Hm = L.hiddenOf(A, M)
  local ds, seen = {}, {}
  for _, d in ipairs(L.doors(A, Hm, true)) do if not seen[d.step] then seen[d.step] = true; ds[#ds + 1] = d.step end end
  local sp = {}
  for _, d in ipairs(L.doors(A, Hm, false)) do sp[d.step] = true end
  local spl = {}
  for s = 0, A.opt do if sp[s] then spl[#spl + 1] = s end end
  print(string.format("  %-46s %5.1f %% (скр %d, жив %d) | %.3f %% | %2d [%s] | путь: %s | все кратчайшие: %s", mk[1], m.hiddenPct, m.hid, m.live, m.smart, m.maxDeep, m.deepList,
    #ds > 0 and table.concat(ds, ",") or "нет", #spl > 0 and table.concat(spl, ",") or "нет"))
end
local M2 = L.mark(A, cls, {})
local ex2 = {}
for i = 1, G.n do if G.flag[i] ~= 2 then ex2[i] = A.VL.expert[i] end end
_G.AN = { A = A, cls = cls, H = H }
return _G.AN
