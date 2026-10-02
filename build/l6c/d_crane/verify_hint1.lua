-- verify_hint1.lua файл.lua — ошибка подсказки №1 («муфту сразу в стояк»): первое по BFS состояние, где муфта C
-- закреплена, а ниппель B ещё не закреплён; печатает глубину, живо ли оно и помечено ли видимым (без ходов и кадров).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local qB, qC
for q, p in ipairs(lvl.pieces) do if p.tag == "B" then qB = q elseif p.tag == "C" then qC = q end end
local cnt, live, vis, mind = 0, 0, 0, 1e9
for i = 1, G.n do
  if G.flag[i] == 0 then
    local st = R.decode(lvl, G.keys[i])
    if st.pos[qC] ~= 0 and st.fixed[qC] and not st.fixed[qB] and st.pos[qB] ~= 0 then
      cnt = cnt + 1
      if good[i] == 1 then live = live + 1 end
      if def.visibleLoss(lvl, st) then vis = vis + 1 end
      if G.depth[i] < mind then mind = G.depth[i] end
    end
  end
end
print(string.format("муфта закреплена раньше ниппеля: состояний %d, живых %d, видимых %d, мин. глубина %d", cnt, live, vis, mind))
-- и шире: любое закрепление муфты до финального хода
local c2, l2 = 0, 0
for i = 1, G.n do
  if G.flag[i] == 0 then
    local st = R.decode(lvl, G.keys[i])
    if st.fixed[qC] then c2 = c2 + 1; if good[i] == 1 then l2 = l2 + 1 end end
  end
end
print(string.format("муфта закреплена (не выигрыш): состояний %d, живых %d", c2, l2))
SV.freeGraph(G); require("ffi").C.free(good)
