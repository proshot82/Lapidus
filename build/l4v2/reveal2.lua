-- build/l4v2/reveal2.lua — для дверей с кратчайших путей: через сколько ходов ошибка «вскрывается» по ходу ложного плана
-- (муфта доведена до машинки и упирается), и сколько ходов можно блуждать. Только метрики.
package.path = "./?.lua;" .. package.path
local AN2 = dofile("build/l4v2/an2.lua")
local A = _G.AN
local G, sts, VL = A.G, A.sts, A.VL
local ES, E, flag = G.eStart.p, G.edges.p, G.flag
for i in pairs(AN2.onSP) do for e = ES[i - 1], ES[i] - 1 do local j = E[e]
  if A.hidden[j] then
    local d, q, h, first, firstAny, cplDown = { [j] = 0 }, { j }, 1, nil, nil, nil
    while h <= #q do local u = q[h]; h = h + 1
      local x, y = A.xy(sts[u].pos[A.qc])
      if y == 6 and cplDown == nil then cplDown = d[u] end
      for ee = ES[u - 1], ES[u] - 1 do local v = E[ee]
        if flag[v] ~= 2 and VL.newbie[v] then
          if firstAny == nil then firstAny = d[u] + 1 end
          if sts[v].pos[A.qc] == A.cell(7, 6) and first == nil then first = d[u] + 1 end
        end
        if A.hidden[v] and d[v] == nil then d[v] = d[u] + 1; q[#q + 1] = v end
      end
    end
    print(string.format("дверь с шага %d: муфта спущена в коридор через %s ходов; упор муфты у машинки (видимо) через %s; любой видимый — через %s",
      G.depth[i], tostring(cplDown), tostring(first), tostring(firstAny)))
  end end end
