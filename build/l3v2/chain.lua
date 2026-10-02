-- build/l3v2/chain.lua — слепой скептик кв. 3 (s8), 30.09. Печатает только метрики и классы, без порядка ходов.
-- 1) двери по фазам на ВСЕХ кратчайших путях; 2) стойкость двери (естественное продолжение ложного плана);
-- 3) обязательность приёмов на всех кратчайших (счёт путей в обход события); 4) узость абляций и контроли.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local path = arg[1] or "build/l3d/s8.lua"
local def = dofile(path)
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local VL = V.compute(lvl, G, def, good)
local ES, E, flag, n = G.eStart.p, G.edges.p, G.flag, G.n
local SQ = {}
for q, p in ipairs(lvl.pieces) do if p.porcelain then SQ[#SQ + 1] = q end end
local UP, LO = SQ[1], SQ[2] -- верхнее (полка), нижнее (пол)
local sts = VL.states
local function hid(j) return flag[j] == 0 and good[j] ~= 1 and not VL.newbie[j] end
local function status(j) if flag[j] == 2 then return "смыт" elseif flag[j] == 1 then return "win" elseif good[j] == 1 then return "live" elseif VL.newbie[j] then return "vis" else return "hid" end end
-- обратный BFS от победы
local cnt = {} for i = 1, n + 1 do cnt[i] = 0 end
for i = 1, n do for e = ES[i-1], ES[i]-1 do cnt[E[e]] = cnt[E[e]] + 1 end end
local st0, s = {}, 1 for i = 1, n do st0[i] = s; s = s + cnt[i] end st0[n+1] = s
local fill, rv = {}, {} for i = 1, n do fill[i] = st0[i] end
for i = 1, n do for e = ES[i-1], ES[i]-1 do local j = E[e]; rv[fill[j]] = i; fill[j] = fill[j] + 1 end end
local dw, q, h = {}, {}, 1
for i = 1, n do if flag[i] == 1 then dw[i] = 0; q[#q+1] = i end end
while h <= #q do local j = q[h]; h = h + 1; for k = st0[j], st0[j+1]-1 do local i = rv[k]; if dw[i] == nil then dw[i] = dw[j] + 1; q[#q+1] = i end end end
local opt = G.depth[G.firstWin]
local onSP = {}
for i = 1, n do if dw[i] and G.depth[i] + dw[i] == opt then onSP[i] = true end end
local function spEdge(i, j) return onSP[i] and onSP[j] and G.depth[j] == G.depth[i] + 1 and dw[j] == dw[i] - 1 end
local function cell(c) if c == 0 then return "смыто" end local x, y = R.xy(lvl, c); return string.format("(%d,%d)", x, y) end
local function cfg(st) return "верх " .. cell(st.pos[UP]) .. ", низ " .. cell(st.pos[LO]) end

-- 1) двери по фазам
print("== 1. двери живое→скрытое / →видимое по фазам кратчайших (все кратчайшие) ==")
local half = opt / 2
local doorCls = {}
for d = 0, opt - 1 do
  local nst, dh, dv, dl = 0, 0, 0, 0
  for i = 1, n do if onSP[i] and G.depth[i] == d then nst = nst + 1
    for e = ES[i-1], ES[i]-1 do local j = E[e]; local sj = status(j)
      if sj == "hid" then dh = dh + 1; local k = cfg(sts[i]) .. " → " .. cfg(sts[j]) .. (d < half and " [1-я половина]" or " [2-я половина]"); doorCls[k] = (doorCls[k] or 0) + 1
      elseif sj == "vis" then dv = dv + 1 elseif sj == "live" or sj == "win" then dl = dl + 1 end end end end
  print(string.format("  фаза %2d: состояний %2d | в живое %3d, в скрытое %2d, в видимое %2d", d, nst, dl, dh, dv))
end
for k, v in pairs(doorCls) do print("  класс двери: " .. k .. "  рёбер " .. v) end

-- 2) стойкость: от каждой двери (из любого живого) — ходов до первого сдвига верхнего мыла и статус после;
-- и минимум ходов до видимого
print("\n== 2. стойкость дверей ==")
local agg = {}
for i = 1, n do if flag[i] == 0 and good[i] == 1 then
  for e = ES[i-1], ES[i]-1 do local j = E[e]
    if hid(j) then
      local up0 = sts[j].pos[UP]
      local d, qq, hh = { [j] = 0 }, { j }, 1
      local firstMove, firstMoveSt, reveal = nil, {}, nil
      while hh <= #qq do local u = qq[hh]; hh = hh + 1
        for ee = ES[u-1], ES[u]-1 do local v = E[ee]
          local sv = status(v)
          if sv == "vis" and not reveal then reveal = d[u] + 1 end
          if sv ~= "smyt" and flag[v] ~= 2 and sts[v].pos[UP] ~= up0 then
            if not firstMove or d[u] + 1 == firstMove then firstMove = d[u] + 1; firstMoveSt[sv .. ":" .. cell(sts[v].pos[UP])] = true end
          end
          if hid(v) and d[v] == nil then d[v] = d[u] + 1; qq[#qq+1] = v end
        end
      end
      local ks = {} for k in pairs(firstMoveSt) do ks[#ks+1] = k end table.sort(ks)
      local key = string.format("вход из фазы %s: вскрытие мин %s; первый сдвиг верхнего мыла через %s ходов → %s",
        onSP[i] and tostring(G.depth[i]) or "вне кратч.", tostring(reveal), tostring(firstMove), table.concat(ks, " "))
      agg[key] = (agg[key] or 0) + 1
    end end end end
for k, v in pairs(agg) do print("  " .. k .. "   (входов " .. v .. ")") end

-- 3) обязательность приёмов на всех кратчайших: число кратчайших путей всего и в обход события
local function below(st, c) return lvl.nb[c][3] end
local function bodyIdx(st, c) for k, b in ipairs(st.body) do if b == c then return k end end end
local function support(st, qq)
  local c = st.pos[qq]; if c == 0 then return "смыто" end
  local b = below(st, c)
  local k = bodyIdx(st, b)
  if k then if k == #st.body then return "голова" elseif k == 1 then return "ноги" else return "тело" end end
  for _, r in ipairs(SQ) do if st.pos[r] == b then return "мыло" end end
  return "стена"
end
local EV = {
  { "подставка выбита (нижнее смыто из-под верхнего)", edge = function(a, b) return a.pos[LO] ~= 0 and b.pos[LO] == 0 and support(a, UP) == "мыло" end },
  { "мыло лежит на мыле", state = function(b) return support(b, UP) == "мыло" end },
  { "мыло лежит на голове", state = function(b) for _, r in ipairs(SQ) do if support(b, r) == "голова" then return true end end end },
  { "мыло лежит на ногах", state = function(b) for _, r in ipairs(SQ) do if support(b, r) == "ноги" then return true end end end },
  { "мыло лежит на середине тела", state = function(b) for _, r in ipairs(SQ) do if support(b, r) == "тело" then return true end end end },
  { "ногами мыло вверх", edge = function(a, b) for _, r in ipairs(SQ) do if a.pos[r] ~= 0 and b.pos[r] == lvl.nb[a.pos[r]][1] then return true end end end },
  { "мыло над Лапидусом над сливом (мост)", state = function(b) local body = {} for _, c in ipairs(b.body) do body[c] = true end
      for _, r in ipairs(SQ) do local c = b.pos[r]; if c ~= 0 then local d = below(b, c); if body[d] and lvl.cell[lvl.nb[d][3]] == 2 then return true end end end end },
  { "длина 5", state = function(b) return #b.body == 5 end },
  { "сжатие (корпус короче)", edge = function(a, b) return #b.body < #a.body end },
}
print("\n== 3. события на кратчайших: путей всего / в обход события ==")
local order = {}
for i = 1, n do if onSP[i] then order[#order+1] = i end end
table.sort(order, function(a, b) return G.depth[a] < G.depth[b] end)
for _, ev in ipairs(EV) do
  local all, avoid = {}, {}
  for _, i in ipairs(order) do
    if i == 1 then all[i] = 1; avoid[i] = (ev.state and ev.state(sts[1])) and 0 or 1 end
    for e = ES[i-1], ES[i]-1 do local j = E[e]
      if spEdge(i, j) then
        all[j] = (all[j] or 0) + (all[i] or 0)
        local blocked = (ev.edge and flag[j] ~= 2 and ev.edge(sts[i], sts[j])) or (ev.state and flag[j] ~= 2 and ev.state(sts[j]))
        avoid[j] = (avoid[j] or 0) + (blocked and 0 or (avoid[i] or 0))
      end end
  end
  local tA, tV = 0, 0
  for i = 1, n do if flag[i] == 1 and onSP[i] then tA = tA + (all[i] or 0); tV = tV + (avoid[i] or 0) end end
  print(string.format("  %-46s путей %d, в обход %d", ev[1], tA, tV))
end
-- последовательность опор верхнего мыла на кратчайших (сжатая) — число различных, длина
local seqs = {}
local function walk(i, acc, last)
  local sp = flag[i] == 2 and "?" or support(sts[i], UP)
  if sp ~= last then acc = acc .. (acc == "" and "" or ">") .. sp end
  if flag[i] == 1 then seqs[acc] = (seqs[acc] or 0) + 1 return end
  for e = ES[i-1], ES[i]-1 do local j = E[e]; if spEdge(i, j) then walk(j, acc, sp) end end
end
walk(1, "", nil)
local ns = 0 for _ in pairs(seqs) do ns = ns + 1 end
print("  различных цепочек опор верхнего мыла на кратчайших: " .. ns .. " (сами цепочки — только в терминал, ниже)")
for k, v in pairs(seqs) do io.stderr:write("    [терминал] " .. k .. " x" .. v .. "\n") end
-- 4) узость абляций: доля рёбер полного графа, которые фильтр запрещает; контроли
print("\n== 4. абляции (доля запрещённых рёбер полного графа) и контроли ==")
local tot = 0
for i = 1, n do tot = tot + (ES[i] - ES[i-1]) end
local function share(f)
  local c = 0
  for i = 1, n do if flag[i] ~= 2 then for e = ES[i-1], ES[i]-1 do local j = E[e]; if flag[j] ~= 2 and not f(lvl, sts[i], sts[j]) then c = c + 1 end end end end
  return 100 * c / tot
end
local F = {}
for _, a in ipairs(def.ablations) do if a.filter then F[#F+1] = { a.name, a.filter, false } end end
local function bs(st) local b = {} for _, c in ipairs(st.body) do b[c] = true end return b end
F[#F+1] = { "К1 нельзя смыть мыло, на котором ничего нет", function(l, a, b)
  for _, r in ipairs(SQ) do if a.pos[r] ~= 0 and b.pos[r] == 0 then
    local up = l.nb[a.pos[r]][1]; local on = false
    for _, r2 in ipairs(SQ) do if a.pos[r2] == up then on = true end end
    if not on then return false end end end return true end, true }
F[#F+1] = { "К2 мыло не лежит на ногах", function(l, a, b) for _, r in ipairs(SQ) do if b.pos[r] ~= 0 and support(b, r) == "ноги" then return false end end return true end, true }
F[#F+1] = { "К3 мыло не лежит на середине тела", function(l, a, b) for _, r in ipairs(SQ) do if b.pos[r] ~= 0 and support(b, r) == "тело" then return false end end return true end, true }
F[#F+1] = { "К4 мыло влево не толкать", function(l, a, b) for _, r in ipairs(SQ) do if a.pos[r] ~= 0 and b.pos[r] ~= 0 and b.pos[r] == l.nb[a.pos[r]][4] then return false end end return true end, true }
F[#F+1] = { "К5 длина не больше 4", function(l, a, b) return #b.body <= 4 end, true }
F[#F+1] = { "К6 сжатий нет", function(l, a, b) return #b.body >= #a.body end, true }
F[#F+1] = { "К7 верхнее мыло не толкать вправо с полки напрямую ногами на полке", function(l, a, b)
  return not (a.pos[UP] == (4 - 1) * l.W + 4 and b.pos[UP] ~= a.pos[UP] and a.pos[LO] ~= 0) end, true }
for _, f in ipairs(F) do
  local G2 = SV.explore(lvl, 3000000, f[2])
  local res = (G2 and G2.firstWin) and string.format("РЕШАЕМ за %d", G2.depth[G2.firstWin]) or "нерешаем"
  print(string.format("  %-58s %s | запрещено рёбер %.1f %%", f[1] .. (f[3] and " [контроль]" or ""), res, share(f[2])))
  if G2 then SV.freeGraph(G2) end
end
SV.freeGraph(G); require("ffi").C.free(good)
