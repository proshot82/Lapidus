-- build/l3v/visrules.lua — строительные блоки альтернативных разметок видимого проигрыша кв. 3 (скептик, 29.09).
-- Геометрия та же, что в levels/03.lua; добавлено правило «запечатано» из прецедента кв. 4 (levels/04.lua, sealed):
-- мыло лежит на твёрдом, а клетку, откуда его толкают к шахте (слева), Лапидусу уже не занять
-- (в кв. 3 это ниша (2,6) шириной в одну клетку: ногам там негде поставить шею).
local STEP_X, STEP_Y = 7, 7
local OPP = { 3, 4, 1, 2 }
local M = {}

function M.geom(lvl, st)
  local g = { step = (STEP_Y - 1) * lvl.W + STEP_X, fixedAt = {}, soapAt = {}, soaps = {}, lap = {}, qsoap = {} }
  for q, p in ipairs(lvl.pieces) do
    local c = st.pos[q]
    if c ~= 0 then
      if st.fixed[q] then g.fixedAt[c] = true end
      if p.porcelain then g.soapAt[c] = true; g.soaps[#g.soaps + 1] = c; g.qsoap[c] = q end
    end
  end
  for _, c in ipairs(st.body) do g.lap[c] = true end
  function g.wall(c) return c == 0 or lvl.cell[c] == 1 or g.fixedAt[c] == true end
  function g.pit(c) return c ~= 0 and lvl.cell[c] == 2 end
  function g.below(c) return lvl.nb[c][3] end
  function g.resting(c)
    local b = g.below(c)
    if g.wall(b) then return true end
    if g.soapAt[b] then return g.resting(b) end
    return false
  end
  -- копия frozen() уровня
  function g.frozen(c)
    if not g.resting(c) then return false end
    for d = 1, 4 do
      local pc, tc = lvl.nb[c][OPP[d]], lvl.nb[c][d]
      if not g.wall(pc) and not g.pit(pc) and not g.wall(tc) then return false end
    end
    return true
  end
  -- копия pocket() уровня
  function g.pocket(c)
    if not g.wall(g.below(c)) then return false end
    for _, d in ipairs({ 2, 4 }) do
      local n = lvl.nb[c][d]
      while n ~= 0 and not g.wall(n) do
        if n == g.step then return false end
        local b = g.below(n)
        if g.pit(b) then break end
        if not g.wall(b) and not g.soapAt[b] then return false end
        n = lvl.nb[n][d]
      end
    end
    return true
  end
  -- «запечатано» (как sealed в кв. 4): мыло на твёрдом; толкать к шахте можно только слева; клетка слева открыта,
  -- но заливка от неё (не через само мыло, не через другое мыло) не доходит ни до одной клетки Лапидуса,
  -- и сам Лапидус там не стоит. Мыло ниже полки (ряд ≥ 6): к шахте — только направо.
  function g.sealed(c)
    if not g.resting(c) then return false end
    local y = math.floor((c - 1) / lvl.W) + 1
    if y < 6 then return false end
    local left = lvl.nb[c][4]
    if left == 0 or lvl.cell[left] ~= 0 or g.soapAt[left] then return false end
    if g.lap[left] then return false end
    local seen, q, h = { [left] = true }, { left }, 1
    while h <= #q do
      local u = q[h]; h = h + 1
      for d = 1, 4 do
        local v = lvl.nb[u][d]
        if v ~= 0 and not seen[v] and v ~= c and lvl.cell[v] == 0 and not g.soapAt[v] then
          if g.lap[v] then return false end
          seen[v] = true; q[#q + 1] = v
        end
      end
    end
    return true
  end
  return g
end

-- Составные разметки. useless(c) — «мыло бесполезно на вид».
-- rule1: любое заклинившее мыло (не на ступеньке) — проигрыш (правило (1) автора).
-- rule2: всё оставшееся мыло бесполезно (смыто/заклинило/карман[/запечатано]).
function M.make(opts)
  return function(lvl, st)
    local g = M.geom(lvl, st)
    if #g.soaps == 0 then return true end
    local function useless(c)
      if g.frozen(c) or g.pocket(c) then return true end
      if opts.sealed and g.sealed(c) then return true end
      return false
    end
    if opts.rule1 then
      for _, c in ipairs(g.soaps) do if c ~= g.step and g.frozen(c) then return true end end
    end
    if opts.expert then
      -- знаток: подставка (мыло на полу под колонкой x=5) потеряна — смыта или заклинила, — а второе мыло ещё не
      -- на Лапидусе и не на ступеньке: поймать его больше нечем.
      local standOK, other = false, nil
      for _, c in ipairs(g.soaps) do
        local x, y = (c - 1) % lvl.W + 1, math.floor((c - 1) / lvl.W) + 1
        if x == 5 and y == 7 then standOK = true end
      end
      if not standOK then
        local held = false
        for _, c in ipairs(g.soaps) do
          if c == g.step then return false end
          local b = g.below(c)
          if g.lap[b] then held = true end
        end
        if not held then return true end
      end
    end
    for _, c in ipairs(g.soaps) do if c == g.step or not useless(c) then return false end end
    return true
  end
end

return M
