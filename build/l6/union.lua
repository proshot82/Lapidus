-- build/l6/union.lua — общий граф состояний для всех стартов раскладки и метрики каждого старта.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local U = {}

-- starts: список состояний (уже устаканенных). Возвращает граф.
function U.build(lvl, starts, cap, filter)
  cap = cap or 400000
  local ids, keys, succ, flag = {}, {}, {}, {}
  local queue = {}
  local function add(st)
    local k = R.key(st)
    local id = ids[k]
    if id then return id end
    id = #keys + 1
    if id > cap then return nil end
    ids[k] = id; keys[id] = k
    if st.dead then flag[id] = 2 elseif R.isWin(lvl, st) then flag[id] = 1 else flag[id] = 0 end
    queue[#queue + 1] = id
    return id
  end
  local sid = {}
  for i, st in ipairs(starts) do sid[i] = add(st) end
  local h = 1
  while h <= #queue do
    local id = queue[h]; h = h + 1
    local out = {}
    if flag[id] == 0 then
      local st = R.decode(lvl, keys[id])
      for m = 1, 8 do
        local mv = R.MOVES[m]
        local ns = R.move(lvl, st, mv.which, mv.dir)
        if ns and filter and not filter(lvl, st, ns) then ns = nil end
        if ns then
          local j = add(ns)
          if not j then return nil end
          out[#out + 1] = j
        end
      end
    end
    succ[id] = out
  end
  local n = #keys
  -- обратные рёбра и расстояние до победы
  local pred = {}
  for i = 1, n do pred[i] = {} end
  for i = 1, n do for _, j in ipairs(succ[i]) do local p = pred[j]; p[#p + 1] = i end end
  local d2g = {}
  local q, qh = {}, 1
  for i = 1, n do if flag[i] == 1 then d2g[i] = 0; q[#q + 1] = i end end
  while qh <= #q do
    local j = q[qh]; qh = qh + 1
    for _, i in ipairs(pred[j]) do
      if d2g[i] == nil and flag[i] == 0 then d2g[i] = d2g[j] + 1; q[#q + 1] = i end
    end
  end
  return { n = n, keys = keys, succ = succ, flag = flag, d2g = d2g, sid = sid, lvl = lvl }
end

-- метрики старта s
function U.metrics(G, s, withMonkey)
  local opt = G.d2g[s]
  if not opt then return nil end
  local succ, flag, d2g = G.succ, G.flag, G.d2g
  -- достижимое из s
  local seen, order = { [s] = true }, { s }
  local h = 1
  while h <= #order do
    local i = order[h]; h = h + 1
    for _, j in ipairs(succ[i]) do if not seen[j] then seen[j] = true; order[#order + 1] = j end end
  end
  local nreach, ndead, nwin = #order, 0, 0
  for _, i in ipairs(order) do
    if not d2g[i] and flag[i] ~= 1 then ndead = ndead + 1 end
    if flag[i] == 1 then nwin = nwin + 1 end
  end
  -- кратчайшие: слои
  local layer, maxw, count = { [s] = 1 }, 1, 0
  for k = 1, opt do
    local nl, w = {}, 0
    for i, c in pairs(layer) do
      for _, j in ipairs(succ[i]) do
        if d2g[j] == d2g[i] - 1 then
          if not nl[j] then w = w + 1 end
          nl[j] = (nl[j] or 0) + c
        end
      end
    end
    if w > maxw then maxw = w end
    layer = nl
  end
  for _, c in pairs(layer) do count = count + c end
  -- путь (первый кратчайший) и «ощущение»
  local path, i = { s }, s
  while flag[i] ~= 1 do
    local best
    for _, j in ipairs(succ[i]) do if d2g[j] == d2g[i] - 1 then best = j; break end end
    i = best; path[#path + 1] = i
  end
  local firstErr, traps, trapSizes = nil, 0, {}
  local seenT = {}
  local safe1 = 0
  for k = 1, #path - 1 do
    local p = path[k]
    local safe = 0
    for _, j in ipairs(succ[p]) do
      if d2g[j] or flag[j] == 1 then safe = safe + 1
      elseif flag[j] ~= 2 then
        if not firstErr then firstErr = k - 1 end
        if not seenT[j] then
          seenT[j] = true
          -- размер области
          local sn, sq, sh = { [j] = true }, { j }, 1
          while sh <= #sq and #sq < 500 do
            local u = sq[sh]; sh = sh + 1
            for _, v in ipairs(succ[u]) do if not sn[v] then sn[v] = true; sq[#sq + 1] = v end end
          end
          traps = traps + 1; trapSizes[#trapSizes + 1] = #sq
        end
      end
    end
    if safe == 1 then safe1 = safe1 + 1 end
  end
  local fb = 0
  for _, sz in ipairs(trapSizes) do if sz >= 50 then fb = fb + 1 end end
  -- события детали вдоль пути: L подъём, P сдвиг вбок, D падение (без смыва)
  local ev = {}
  local lvl = G.lvl
  local streak, maxStreak, frun, maxF = 0, 0, 0, 0
  for k = 1, #path - 1 do
    local a, b = R.decode(lvl, G.keys[path[k]]), R.decode(lvl, G.keys[path[k + 1]])
    local evHere = false
    for q = 1, #a.pos do if a.pos[q] ~= b.pos[q] or a.fixed[q] ~= b.fixed[q] then evHere = true end end
    if evHere then streak = 0 else streak = streak + 1; if streak > maxStreak then maxStreak = streak end end
    local safeK = 0
    for _, j in ipairs(succ[path[k]]) do if d2g[j] or flag[j] == 1 then safeK = safeK + 1 end end
    if safeK == 1 then frun = frun + 1; if frun > maxF then maxF = frun end else frun = 0 end
    for q = 1, #a.pos do
      if a.pos[q] ~= b.pos[q] and a.pos[q] ~= 0 and b.pos[q] ~= 0 and lvl.pieces[q].movable then
        local ax, ay = R.xy(lvl, a.pos[q]); local bx, by = R.xy(lvl, b.pos[q])
        if by < ay then ev[#ev + 1] = "L" elseif bx ~= ax then ev[#ev + 1] = "P" else ev[#ev + 1] = "D" end
      elseif a.fixed[q] ~= b.fixed[q] then ev[#ev + 1] = "F"
      end
    end
  end
  local res = { opt = opt, reach = nreach, deadPct = 100 * ndead / nreach, wins = nwin, count = count, maxw = maxw,
    firstErr = firstErr, traps = traps, fb = fb, path = path, safe1 = safe1, ev = table.concat(ev), walk = maxStreak, frun = maxF }
  if withMonkey then
    local T = 5 * opt
    local p, ok = { [s] = 1.0 }, 0
    for _ = 1, T do
      local np = {}
      for i2, pr in pairs(p) do
        local out = succ[i2]
        local k = #out
        if k > 0 then
          local share = pr / k
          for _, j in ipairs(out) do
            if flag[j] == 1 then ok = ok + share
            elseif flag[j] == 2 then np[i2] = (np[i2] or 0) + share
            else np[j] = (np[j] or 0) + share end
          end
        end
      end
      p = np
    end
    res.monkey = 100 * (1 - (1 - ok) ^ (1000 / T))
  end
  return res
end
return U
