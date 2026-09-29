-- gvis3.lua — ТОЧНАЯ (по графу состояний) «самая широкая честная» разметка видимого проигрыша (разведка ядер кв. 7).
-- local GV = dofile("build/l7c/d_tee_lift/gvis3.lua"); def.visModes = GV.modes(def)
-- Режимы: static (W F J I L), wide (static + N), why (буква правила; для диагностики);
--   strict  = wide + D: какая-то деталь уже НИКОГДА не встанет на своё финальное место (точно; шире любой честной);
--   strictL = strict + d: Лапидус уже никогда не примет финальную позу (в т.ч. «не тем концом»).
-- В strict/strictL скрытыми остаются только тупики-«сочетания»: каждая деталь по отдельности ещё может встать на место.
-- Финальная сборка — единственное выигрышное состояние (если их больше — берётся первое и печатается предупреждение).
--  W  смыта деталь (делает check.lua / qm.lua сам);
--  F  деталь закреплена не там, где в финале;
--  J  две свободные детали свинчены, а в финале они не в одной сборке или с другим сдвигом;
--  I  деталь не на месте и больше НИКОГДА не сдвинется (точно, по графу) — сюда входит и «лишняя деталь навсегда
--     на клетке финальной сборки»;
--  L  деталь ниже своей финальной строки и больше НИКОГДА не поднимется (точно, по графу) — «груз, который надо
--     поднять, лежит вне струи»;
--  N  проигрыш вскрывается следующим толчком: что бы ни делал Лапидус, первый же ход, сдвигающий или свинчивающий
--     детали, ведёт в видимое по W/F/J/I/L (или детали уже не сдвинутся никогда).
-- Живые состояния эта разметка не помечает никогда (I и L — только у деталей, которые ещё должны двигаться/подняться).
local R = require("core.rules")
local SV = require("solver.solve")
local ffi = require("ffi")
local M = {}

function M.modes(def, opts)
  opts = opts or {}
  local marks -- key -> "F"/"J"/"I"/"L"/"N"/"W"/false
  local function build()
    local d = {}
    for k, v in pairs(def) do d[k] = v end
    d.visibleLoss = nil; d.visModes = nil
    local L = R.compile(d)
    local G = assert(SV.explore(L, opts.cap or 5000000), "cap")
    assert(G.firstWin, "нет решения")
    local n = G.n
    local E, ES = G.edges.p, G.eStart.p
    local P = L.pieces
    local np = #P
    local nwin = 0
    for i = 1, n do if G.flag[i] == 1 then nwin = nwin + 1 end end
    if nwin > 1 then io.stderr:write("gvis3: выигрышных состояний " .. nwin .. ", беру первое\n") end
    local fin = R.decode(L, G.keys[G.firstWin])
    local W = L.W
    -- позиции деталей по состояниям
    local pos, fx, asm = {}, {}, {}
    for q = 1, np do
      pos[q] = ffi.new("int16_t[?]", n + 1)
      fx[q] = ffi.new("uint8_t[?]", n + 1)
      asm[q] = ffi.new("uint8_t[?]", n + 1)
    end
    for i = 1, n do
      local st = R.decode(L, G.keys[i])
      for q = 1, np do pos[q][i] = st.pos[q]; fx[q][i] = st.fixed[q] and 1 or 0; asm[q][i] = st.asm[q] end
    end
    local function row(c) return math.floor((c - 1) / W) + 1 end
    -- обратные рёбра
    local indeg = ffi.new("int32_t[?]", n + 2)
    for i = 1, n do for e = ES[i - 1], ES[i] - 1 do indeg[E[e]] = indeg[E[e]] + 1 end end
    local off = ffi.new("int32_t[?]", n + 2)
    local acc = 0
    for i = 1, n do off[i] = acc; acc = acc + indeg[i] end
    off[n + 1] = acc
    local rev = ffi.new("int32_t[?]", acc + 1)
    local fill = ffi.new("int32_t[?]", n + 2)
    for i = 1, n do
      for e = ES[i - 1], ES[i] - 1 do local j = E[e]; rev[off[j] + fill[j]] = i; fill[j] = fill[j] + 1 end
    end
    local queue = ffi.new("int32_t[?]", n + 2)
    local function backClosure(seed) -- seed: uint8 массив, 1 = источник; дополняет до всех предков
      local qh, qt = 0, 0
      for i = 1, n do if seed[i] == 1 then queue[qt] = i; qt = qt + 1 end end
      while qh < qt do
        local j = queue[qh]; qh = qh + 1
        for e = off[j], off[j + 1] - 1 do
          local i = rev[e]
          if seed[i] == 0 and G.flag[i] == 0 then seed[i] = 1; queue[qt] = i; qt = qt + 1 end
        end
      end
    end
    -- canMove[q], canRise[q]
    local canMove, canRise = {}, {}
    for q = 1, np do
      if P[q].movable then
        local cm = ffi.new("uint8_t[?]", n + 2)
        local cr = ffi.new("uint8_t[?]", n + 2)
        local pq = pos[q]
        for i = 1, n do
          if G.flag[i] == 0 then
            local a = pq[i]
            for e = ES[i - 1], ES[i] - 1 do
              local j = E[e]
              if G.flag[j] ~= 2 then
                local b = pq[j]
                if b ~= a then
                  cm[i] = 1
                  if a ~= 0 and b ~= 0 and row(b) < row(a) then cr[i] = 1 end
                end
              end
            end
          end
        end
        backClosure(cm); backClosure(cr)
        canMove[q], canRise[q] = cm, cr
      end
    end
    -- canReach[q]: деталь q ещё может встать на своё финальное место (точно); canLap: Лапидус — в финальную позу
    local canReach = {}
    for q = 1, np do
      if P[q].movable then
        local cr = ffi.new("uint8_t[?]", n + 2)
        for i = 1, n do if G.flag[i] ~= 2 and pos[q][i] == fin.pos[q] then cr[i] = 1 end end
        backClosure(cr)
        canReach[q] = cr
      end
    end
    local finBody = table.concat(fin.body, ",")
    local canLap = ffi.new("uint8_t[?]", n + 2)
    for i = 1, n do
      if G.flag[i] ~= 2 then
        local st = R.decode(L, G.keys[i])
        if table.concat(st.body, ",") == finBody then canLap[i] = 1 end
      end
    end
    backClosure(canLap)
    -- статическая разметка
    local stat = {}
    for i = 1, n do
      local w = false
      if G.flag[i] == 0 then
        for q = 1, np do
          if P[q].movable then
            local c = pos[q][i]
            if c == 0 then if not def.washOk then w = "W" end
            elseif fx[q][i] == 1 and c ~= fin.pos[q] then w = "F" end
          end
          if w then break end
        end
        if not w then
          for a = 1, np do
            if P[a].movable and pos[a][i] ~= 0 and fx[a][i] == 0 then
              for b = a + 1, np do
                if P[b].movable and pos[b][i] ~= 0 and fx[b][i] == 0 and asm[a][i] == asm[b][i] then
                  if not (fin.asm[a] == fin.asm[b] and pos[b][i] - pos[a][i] == fin.pos[b] - fin.pos[a]) then w = "J" end
                end
              end
            end
            if w then break end
          end
        end
        if not w then
          for q = 1, np do
            if P[q].movable then
              local c = pos[q][i]
              if c ~= 0 and fx[q][i] == 0 then
                if c ~= fin.pos[q] and canMove[q][i] == 0 then w = "I"; break end
                if fin.pos[q] ~= 0 and row(c) > row(fin.pos[q]) and canRise[q][i] == 0 then w = "L"; break end
              end
            end
          end
        end
      end
      stat[i] = w
    end
    -- N: наибольшая неподвижная точка
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
    -- удаляем тех, у кого ход одним Лапидусом ведёт в невидимое вне C
    local changed = true
    while changed do
      changed = false
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
          if inC[i] == 1 and sameP(i, j) then inC[i] = 0; queue[qt] = i; qt = qt + 1; changed = true end
        end
      end
    end
    marks = {}
    for i = 1, n do
      local m = stat[i]
      if not m and inC[i] == 1 then m = "N" end
      if not m and G.flag[i] == 0 then
        for q = 1, np do
          if P[q].movable and canReach[q][i] == 0 then m = "D"; break end
        end
        if not m and canLap[i] == 0 then m = "d" end
      end
      marks[G.keys[i]] = m or false
    end
    M.lastFinal = fin
    SV.freeGraph(G)
  end
  local function why(lvl, st)
    if not marks then build() end
    local m = marks[R.key(st)]
    if m == nil then return false end
    return m
  end
  return {
    static = function(lvl, st) local m = why(lvl, st); return (m and m ~= "N" and m ~= "D" and m ~= "d") and true or false end,
    wide = function(lvl, st) local m = why(lvl, st); return (m and m ~= "D" and m ~= "d") and true or false end,
    strict = function(lvl, st) local m = why(lvl, st); return (m and m ~= "d") and true or false end,
    strictL = function(lvl, st) return why(lvl, st) and true or false end,
    why = why,
  }
end
return M
