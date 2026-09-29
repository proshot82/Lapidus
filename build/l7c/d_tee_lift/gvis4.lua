-- gvis4.lua — разметка «в духе скептиков» (статичные признаки, как verify2_vis "honest"), но корректная:
-- толчки цепочкой, слив, «фонтана больше нет навсегда»; плюс N (следующий толчок вскрывает) по графу.
-- compute(L, G, def) -> массив id -> буква или false. Правила:
--  W смыта деталь; F закреплена не там; J свинчены не как в финале;
--  I деталь не на месте лежит на твёрдом вне струй и не сдвигается ни влево, ни вправо: впереди стена/закреплённое
--    либо сзади негде встать толкающему (стена, закреплённое, слив, или туда не добраться даже сквозь подвижное);
--  L деталь ниже своей финальной строки лежит на твёрдом вне столба-лифта, и по своему ряду её в столб не втолкнуть
--    (или фонтана нет и больше не будет: все начальные струи вверх заткнуты закреплённым);
--  N следующий толчок вскрывает проигрыш (как в gvis3).
local R = require("core.rules")
local ffi = require("ffi")
local M = {}

function M.compute(L, G, def)
  local n = G.n
  local E, ES = G.edges.p, G.eStart.p
  local P = L.pieces
  local np = #P
  local fin = R.decode(L, G.keys[G.firstWin])
  local W = L.W
  local function row(c) return math.floor((c - 1) / W) + 1 end
  -- начальные источники струй вверх
  local st0 = R.newState(L)
  local origins = {}
  for _, j in ipairs(R.jets(L, st0)) do if j.dir == R.UP and not j.lapidus then origins[#origins + 1] = j.cell end end
  local function static(st)
    for q, p in ipairs(P) do
      if p.movable then
        if st.pos[q] == 0 then if not def.washOk then return "W" end
        elseif st.fixed[q] and st.pos[q] ~= fin.pos[q] then return "F" end
      end
    end
    for a = 1, np do
      if P[a].movable and st.pos[a] ~= 0 and not st.fixed[a] then
        for b = a + 1, np do
          if P[b].movable and st.pos[b] ~= 0 and not st.fixed[b] and st.asm[a] == st.asm[b] then
            if not (fin.asm[a] == fin.asm[b] and st.pos[b] - st.pos[a] == fin.pos[b] - fin.pos[a]) then return "J" end
          end
        end
      end
    end
    local occ = {}
    for q = 1, np do if st.pos[q] ~= 0 then occ[st.pos[q]] = q end end
    local function fixedAt(c) local r = occ[c]; return r and st.fixed[r] end
    local function solid(c) return c == 0 or L.cell[c] == R.WALL or fixedAt(c) end
    local jet, col, anyUp = {}, {}, false
    for _, j in ipairs(R.jets(L, st)) do
      for _, c in ipairs(j.cells) do jet[c] = true end
      if j.dir == R.UP and #j.cells > 0 then
        anyUp = true
        for _, c in ipairs(j.cells) do col[c] = true end
        local t = L.nb[j.cells[#j.cells]][R.UP]
        if t ~= 0 then col[t] = true end
      end
    end
    local gone = false
    if not anyUp and #origins > 0 then
      gone = true
      for _, c in ipairs(origins) do
        local u = L.nb[c][R.UP]
        if not (u ~= 0 and fixedAt(u)) then gone = false end
      end
    end
    -- заливка «Лапидус как точка»: сквозь пустое и подвижное, не сквозь стену, закреплённое и слив
    local reach, qq, h = {}, {}, 1
    for _, c in ipairs(st.body) do reach[c] = true; qq[#qq + 1] = c end
    while h <= #qq do
      local u = qq[h]; h = h + 1
      for d = 1, 4 do
        local v = L.nb[u][d]
        if v ~= 0 and not reach[v] and L.cell[v] == R.EMPTY and not fixedAt(v) then reach[v] = true; qq[#qq + 1] = v end
      end
    end
    local function pusherOk(back)
      return back ~= 0 and not solid(back) and L.cell[back] ~= R.PIT and reach[back]
    end
    for q, p in ipairs(P) do
      local c = st.pos[q]
      if p.movable and c ~= 0 and not st.fixed[q] then
        local onSolid = solid(L.nb[c][R.DOWN])
        if c ~= fin.pos[q] and onSolid and not jet[c] and not col[c] then
          local stuck = true
          for _, d in ipairs({ R.LEFT, R.RIGHT }) do
            local fwd, back = L.nb[c][d], L.nb[c][R.OPP[d]]
            if not solid(fwd) and pusherOk(back) then stuck = false end
          end
          if stuck then return "I" end
        end
        if fin.pos[q] ~= 0 and row(c) > row(fin.pos[q]) and onSolid and not col[c] then
          local ok = false
          if anyUp then
            for _, d in ipairs({ R.LEFT, R.RIGHT }) do
              if pusherOk(L.nb[c][R.OPP[d]]) then
                local t = c
                while true do
                  t = L.nb[t][d]
                  if t == 0 or solid(t) then break end
                  if col[t] then ok = true; break end
                end
              end
            end
          elseif not gone then ok = true end
          if not ok then return "L" end
        end
      end
    end
    return false
  end
  local stat = {}
  local pos, fx, asm = {}, {}, {}
  for q = 1, np do pos[q] = ffi.new("int16_t[?]", n + 1); fx[q] = ffi.new("uint8_t[?]", n + 1); asm[q] = ffi.new("uint8_t[?]", n + 1) end
  for i = 1, n do
    local st = R.decode(L, G.keys[i])
    for q = 1, np do pos[q][i] = st.pos[q]; fx[q][i] = st.fixed[q] and 1 or 0; asm[q][i] = st.asm[q] end
    stat[i] = (G.flag[i] == 0) and static(st) or false
  end
  local indeg = ffi.new("int32_t[?]", n + 2)
  for i = 1, n do for e = ES[i - 1], ES[i] - 1 do indeg[E[e]] = indeg[E[e]] + 1 end end
  local off = ffi.new("int32_t[?]", n + 2)
  local acc = 0
  for i = 1, n do off[i] = acc; acc = acc + indeg[i] end
  off[n + 1] = acc
  local rev = ffi.new("int32_t[?]", acc + 1)
  local fill = ffi.new("int32_t[?]", n + 2)
  for i = 1, n do for e = ES[i - 1], ES[i] - 1 do local j = E[e]; rev[off[j] + fill[j]] = i; fill[j] = fill[j] + 1 end end
  local queue = ffi.new("int32_t[?]", n + 2)
  local function sameP(i, j)
    for q = 1, np do if pos[q][i] ~= pos[q][j] or fx[q][i] ~= fx[q][j] or asm[q][i] ~= asm[q][j] then return false end end
    return true
  end
  local inC = ffi.new("uint8_t[?]", n + 2)
  for i = 1, n do
    if G.flag[i] == 0 and not stat[i] then
      local ok = 1
      for e = ES[i - 1], ES[i] - 1 do
        local j = E[e]
        if G.flag[j] == 1 then ok = 0; break end
        if G.flag[j] == 0 and not stat[j] and not sameP(i, j) then ok = 0; break end
      end
      inC[i] = ok
    end
  end
  local qh, qt = 0, 0
  for i = 1, n do
    if inC[i] == 1 then
      for e = ES[i - 1], ES[i] - 1 do
        local j = E[e]
        if G.flag[j] == 0 and not stat[j] and inC[j] == 0 and sameP(i, j) then inC[i] = 0; queue[qt] = i; qt = qt + 1; break end
      end
    end
  end
  while qh < qt do
    local j = queue[qh]; qh = qh + 1
    for e = off[j], off[j + 1] - 1 do
      local i = rev[e]
      if inC[i] == 1 and sameP(i, j) then inC[i] = 0; queue[qt] = i; qt = qt + 1 end
    end
  end
  local out = {}
  for i = 1, n do
    local m = stat[i]
    if not m and inC[i] == 1 then m = "N" end
    out[i] = m or false
  end
  return out
end
return M
