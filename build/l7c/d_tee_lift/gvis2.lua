-- gvis2.lua — «самая широкая честная» разметка видимого проигрыша в духе скептиков (для разведки ядер).
-- local GV = dofile("build/l7c/d_tee_lift/gvis2.lua"); def.visModes = GV.modes(def, opts)
-- Финальная сборка — из единственного выигрышного состояния (считается один раз).
-- Правила (видно, если знать финальную сборку):
--  W  смыта деталь (делает check.lua сам);
--  F  деталь закреплена не там, где в финале;
--  J  две детали свинчены (одна сборка), а в финале они не свинчены именно так;
--  I  деталь не на месте и статически больше не сдвинется: лежит на твёрдом, вне струй, и в каждую сторону
--     либо упор, либо толкателю негде встать (твёрдое/слив), либо до клетки толкателя Лапидусу (как точке) не дойти;
--  X  то же для детали, лежащей на клетке финальной сборки (чужой или тела Лапидуса);
--  L  деталь ниже своей финальной строки лежит на твёрдом вне столба-лифта и по своему ряду в столб не вталкивается;
--  N  (режим "wide") проигрыш вскрывается следующим толчком: что бы Лапидус ни делал, первый же ход, который
--     сдвинет или свинтит детали, приводит в видимое по W/F/J/I/X/L (или детали уже не сдвинуть никогда).
local R = require("core.rules")
local SV = require("solver.solve")
local M = {}

function M.final(def)
  local d = {}
  for k, v in pairs(def) do d[k] = v end
  d.visibleLoss = nil; d.visModes = nil
  local lvl = R.compile(d)
  local G = SV.explore(lvl, 3000000)
  assert(G and G.firstWin, "нет решения")
  local st = R.decode(lvl, G.keys[G.firstWin])
  SV.freeGraph(G)
  return st
end

local function build(def, opts)
  opts = opts or {}
  local fin
  local function static(lvl, st)
    fin = fin or M.final(def)
    local P = lvl.pieces
    local occ = {}
    for q = 1, #st.pos do if st.pos[q] ~= 0 then occ[st.pos[q]] = q end end
    local function solid(c) if c == 0 or lvl.cell[c] == R.WALL then return true end local r = occ[c]; return r and st.fixed[r] end
    for q, p in ipairs(P) do
      if p.movable and st.pos[q] ~= 0 and st.fixed[q] and st.pos[q] ~= fin.pos[q] then return "F" end
    end
    for a = 1, #P do for b = a + 1, #P do
      if P[a].movable and P[b].movable and st.pos[a] ~= 0 and st.pos[b] ~= 0 and not st.fixed[a] and not st.fixed[b] and st.asm[a] == st.asm[b] then
        -- в финале пара должна стоять с тем же сдвигом и быть свинчена
        local dxs = st.pos[b] - st.pos[a]
        local dxf = fin.pos[b] - fin.pos[a]
        local d = R.dirBetween(lvl, fin.pos[a], fin.pos[b])
        local fj = d and P[a].ports[d] and P[b].ports[R.OPP[d]] and R.match(P[a].ports[d], P[b].ports[R.OPP[d]])
        if not fj or dxs ~= dxf then return "J" end
      end
    end end
    local jet, col = {}, {}
    local anyUp = false
    for _, j in ipairs(R.jets(lvl, st)) do
      for _, c in ipairs(j.cells) do jet[c] = true end
      if j.dir == R.UP and #j.cells > 0 then
        anyUp = true
        for _, c in ipairs(j.cells) do col[c] = true end
        local t = lvl.nb[j.cells[#j.cells]][R.UP]; if t ~= 0 then col[t] = true end
      end
    end
    local finalCells = {}
    for q = 1, #fin.pos do if fin.pos[q] ~= 0 and lvl.pieces[q].movable then finalCells[fin.pos[q]] = q end end
    for _, c in ipairs(fin.body) do finalCells[c] = "L" end
    -- заливка «Лапидус как точка» по пустым клеткам (не стена, не деталь, не слив)
    local reach, qq, h = {}, {}, 1
    for _, c in ipairs(st.body) do reach[c] = true; qq[#qq + 1] = c end
    while h <= #qq do
      local u = qq[h]; h = h + 1
      for d = 1, 4 do
        local v = lvl.nb[u][d]
        if v ~= 0 and not reach[v] and lvl.cell[v] == R.EMPTY and not occ[v] then reach[v] = true; qq[#qq + 1] = v end
      end
    end
    local function immobile(c)
      if jet[c] or col[c] then return false end
      local below = lvl.nb[c][R.DOWN]
      if not solid(below) then return false end
      for _, d in ipairs({ R.LEFT, R.RIGHT }) do
        local fwd, back = lvl.nb[c][d], lvl.nb[c][R.OPP[d]]
        local pushOk = back ~= 0 and not solid(back) and lvl.cell[back] ~= R.PIT and reach[back]
        if not solid(fwd) and pushOk then return false end
      end
      return true
    end
    for q, p in ipairs(P) do
      local c = st.pos[q]
      if p.movable and c ~= 0 and not st.fixed[q] then
        if c ~= fin.pos[q] and immobile(c) then return finalCells[c] and "X" or "I" end
        local fy = select(2, R.xy(lvl, fin.pos[q]))
        local x, y = R.xy(lvl, c)
        if y > fy and solid(lvl.nb[c][R.DOWN]) and not col[c] then
          local ok = false
          if anyUp then
            for _, dd in ipairs({ R.LEFT, R.RIGHT }) do
              local t = c
              while true do
                t = lvl.nb[t][dd]
                if t == 0 or solid(t) then break end
                if col[t] then ok = true; break end
              end
            end
          end
          if not ok then return "L" end
        end
      end
    end
    return false
  end
  -- N: «проигрыш вскрывается следующим толчком». Компонента = состояния с той же расстановкой деталей,
  -- достижимые ходами одного Лапидуса. Если в ней нет победы и КАЖДЫЙ выход из неё (любой ход, сдвигающий или
  -- свинчивающий детали) ведёт в видимое по W/F/J/I/X/L — помечаем. Компонента без выходов и без победы — застой
  -- (ни одна деталь больше не сдвинется) — тоже видна. Живые состояния так не помечаются никогда.
  local compCache = {}
  local function pieceKey(st)
    local t = {}
    for q = 1, #st.pos do t[#t + 1] = st.pos[q] .. (st.fixed[q] and "f" or "") .. ":" .. st.asm[q] end
    return table.concat(t, ",")
  end
  local function compN(lvl, st)
    local k = R.key(st)
    local c = compCache[k]
    if c ~= nil then return c end
    local pk = pieceKey(st)
    local seen, list, h = { [k] = true }, { st }, 1
    local verdict = true
    while h <= #list do
      local s = list[h]; h = h + 1
      if R.isWin(lvl, s) then verdict = false end
      for m = 1, 8 do
        local mm = R.MOVES[m]
        local ns = R.move(lvl, s, mm.which, mm.dir)
        if ns and not ns.dead then
          if pieceKey(ns) == pk then
            local nk = R.key(ns)
            if not seen[nk] then seen[nk] = true; list[#list + 1] = ns end
          elseif verdict then
            local v = false
            for q, p in ipairs(lvl.pieces) do if p.movable and ns.pos[q] == 0 then v = true end end
            if not v then v = static(lvl, ns) and true or false end
            if not v then verdict = false end
          end
        end
      end
    end
    for kk in pairs(seen) do compCache[kk] = verdict end
    return verdict
  end
  local function wide(lvl, st)
    local s = static(lvl, st)
    if s then return s end
    if st.dead then return false end
    fin = fin or M.final(def)
    if compN(lvl, st) then return "N" end
    return false
  end
  return static, wide
end

function M.modes(def, opts)
  local static, wide = build(def, opts)
  return {
    static = function(lvl, st) return static(lvl, st) and true or false end,
    wide = function(lvl, st) return wide(lvl, st) and true or false end,
    why = wide,
  }
end
return M
