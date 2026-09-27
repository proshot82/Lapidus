-- Проверка заявленных «ага» кв. 2–5 на графе состояний.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local function load(id)
  local def = dofile(string.format("levels/%02d.lua", id))
  local lvl = R.compile(def)
  local G = SV.explore(lvl, 3000000)
  local good = SV.goodSet(G)
  return def, lvl, G, good
end
local function q(lvl, what) for i, p in ipairs(lvl.pieces) do if p.what == what or p.tag == what then return i end end end
local function show(lvl, st)
  local rows = {}
  for y = 1, lvl.H do rows[y] = {} for x = 1, lvl.W do local c = lvl.cell[(y-1)*lvl.W+x]; rows[y][x] = c == 1 and "#" or (c == 2 and "~" or ".") end end
  local SYM = { source = "S", fixture = "F", stub = "T", pipe = "=", fitting = "b", porcelain = "p" }
  for qq, p in ipairs(lvl.pieces) do if st.pos[qq] ~= 0 then local x, y = R.xy(lvl, st.pos[qq]); rows[y][x] = (st.fixed[qq] and p.movable) and SYM[p.kind]:upper() or SYM[p.kind] end end
  for i, c in ipairs(st.body) do local x, y = R.xy(lvl, c); rows[y][x] = (i == #st.body) and "H" or (i == 1 and "f" or "o") end
  local out = {}
  for y = 1, lvl.H do out[#out+1] = "      " .. table.concat(rows[y]) end
  return table.concat(out, "\n")
end
-- кв. 4: предварительная сборка муфты с ниппелем и «ниппель первым»
do
  local def, lvl, G, good = load(4)
  local qc, qn = q(lvl, "coupling"), q(lvl, "nipple")
  local asmLive, asmDead, nipFirstLive, nipFirstDead = 0, 0, 0, 0
  for i = 1, G.n do
    if G.flag[i] ~= 2 then
      local st = R.decode(lvl, G.keys[i])
      if st.pos[qc] ~= 0 and st.pos[qn] ~= 0 and st.asm[qc] == st.asm[qn] and not st.fixed[qc] then
        if good[i] == 1 then asmLive = asmLive + 1 else asmDead = asmDead + 1 end
      end
      -- ниппель лежит на стояке (прямо над ним), муфта не закреплена
      local src
      for k, p in ipairs(lvl.pieces) do if p.kind == "source" then src = p.start end end
      if st.pos[qn] == lvl.nb[src][R.UP] and not st.fixed[qc] then
        if good[i] == 1 then nipFirstLive = nipFirstLive + 1 else nipFirstDead = nipFirstDead + 1 end
      end
    end
  end
  print(string.format("кв. 4: состояний «муфта и ниппель свинчены заранее» — живых %d, мёртвых %d; «ниппель лёг на стояк первым» — живых %d, мёртвых %d",
    asmLive, asmDead, nipFirstLive, nipFirstDead))
  SV.freeGraph(G); require("ffi").C.free(good)
end
-- кв. 5: заглушка прикручена к тройнику, пока тройник ещё на полке / до установки
do
  local def, lvl, G, good = load(5)
  local qt, qp = q(lvl, "tee"), q(lvl, "plug")
  local early = { live = 0, dead = 0 }
  local reachEarly = false
  for i = 1, G.n do
    if G.flag[i] ~= 2 then
      local st = R.decode(lvl, G.keys[i])
      if st.pos[qt] ~= 0 and st.pos[qp] ~= 0 and st.asm[qt] == st.asm[qp] and not st.fixed[qt] then
        reachEarly = true
        if good[i] == 1 then early.live = early.live + 1 else early.dead = early.dead + 1 end
      end
    end
  end
  print(string.format("кв. 5: состояний «заглушка свинчена с тройником до его установки» — живых %d, мёртвых %d", early.live, early.dead))
  SV.freeGraph(G); require("ffi").C.free(good)
end
-- кв. 3: какие первые ходы ведут в большую скрытую ловушку
do
  local def, lvl, G, good = load(3)
  local st0 = R.decode(lvl, G.keys[1])
  print("кв. 3: старт\n" .. show(lvl, st0))
  for e = G.eStart.p[0], G.eStart.p[1] - 1 do
    local j = G.edges.p[e]
    local st = R.decode(lvl, G.keys[j])
    print(string.format("   ход → %s", good[j] == 1 and "живое" or (G.flag[j] == 2 and "смыло" or "ТУПИК")))
  end
  -- доля состояний с ногами на стояке: живые/мёртвые
  local qs
  for k, p in ipairs(lvl.pieces) do if p.kind == "source" then qs = k end end
  local fl, fd = 0, 0
  for i = 1, G.n do
    if G.flag[i] == 0 then
      local st = R.decode(lvl, G.keys[i])
      local occ = R.occupancy(st)
      local hs = R.endScrew(lvl, st, occ, "heel")
      if hs == qs then if good[i] == 1 then fl = fl + 1 else fd = fd + 1 end end
    end
  end
  print(string.format("кв. 3: состояний «ноги уже на стояке» — живых %d, мёртвых %d", fl, fd))
  SV.freeGraph(G); require("ffi").C.free(good)
end
-- кв. 2: представитель скрытой ловушки
do
  local def, lvl, G, good = load(2)
  local shown = 0
  for i = 1, G.n do
    if G.flag[i] == 0 and good[i] ~= 1 and shown < 2 then
      local st = R.decode(lvl, G.keys[i])
      print("кв. 2: пример скрытого тупика\n" .. show(lvl, st)); shown = shown + 1
    end
  end
  SV.freeGraph(G); require("ffi").C.free(good)
end
