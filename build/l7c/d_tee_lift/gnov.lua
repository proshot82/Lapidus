-- gnov.lua — МЕРКА НОВИЧКА (docs/DESIGN.md §7, решение Lao 29.09) по графу состояний: compute(L, G, def) -> id -> буква/false.
-- Игрок знает правила и карточки, но не решение. Видимо проиграно, если:
--  W  деталь смыта (кроме washOk);
--  I  нужная деталь больше НИКОГДА не сдвинется (сокобан-угол, зажата, запечатана) — точно, по графу; деталь не на своём
--     финальном месте и не закреплена;
--  L  деталь, которую надо поднять (ниже своей финальной строки), лежит там, где её нечем поднять: больше НИКОГДА не
--     поднимется (точно, по графу);
--  O  прибор, стояк или выход сети навсегда заняты деталью (закреплена не на своём месте), чья резьба явно никуда
--     не ведёт: других резьб нет или все они смотрят в стену.
-- Скрыто для новичка: порядок деталей, неверная пара, деталь не на своём месте (если для этого нужна финальная сборка).
-- Точные «никогда» (I, L) — самое широкое прочтение правил новичка (сужение запрещено).
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
  local pos, fx = {}, {}
  for q = 1, np do pos[q] = ffi.new("int16_t[?]", n + 1); fx[q] = ffi.new("uint8_t[?]", n + 1) end
  for i = 1, n do
    local st = R.decode(L, G.keys[i])
    for q = 1, np do pos[q][i] = st.pos[q]; fx[q][i] = st.fixed[q] and 1 or 0 end
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
  local function backClosure(seed)
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
  -- исходно закреплённые объекты (стояк, трубы, тройник, приборы, отводы) — их выходы
  local base = {}
  for q, p in ipairs(P) do if not p.movable then base[p.start] = q end end
  local out = {}
  for i = 1, n do
    local m = false
    if G.flag[i] == 0 then
      for q = 1, np do
        local p = P[q]
        if p.movable then
          local c = pos[q][i]
          if c == 0 then
            if not def.washOk then m = "W" end
          elseif fx[q][i] == 0 then
            if c ~= fin.pos[q] and canMove[q][i] == 0 then m = "I"
            elseif fin.pos[q] ~= 0 and row(c) > row(fin.pos[q]) and canRise[q][i] == 0 then m = "L" end
          elseif c ~= fin.pos[q] then
            -- O: вкручена в исходно закреплённый объект и дальше никуда не ведёт
            local intoBase, other = false, false
            for d = 1, 4 do
              local th = p.ports[d]
              if th then
                local t = L.nb[c][d]
                local b = t ~= 0 and base[t]
                if b and P[b].ports[R.OPP[d]] and R.match(th, P[b].ports[R.OPP[d]]) then intoBase = true
                elseif t ~= 0 and L.cell[t] ~= R.WALL then other = true end
              end
            end
            if intoBase and not other then m = "O" end
          end
          if m then break end
        end
      end
    end
    out[i] = m
  end
  return out
end
return M
