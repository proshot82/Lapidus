-- build/l3c/vis.lua — правила «видимо проиграно» для семейства кв. 3 (фаянс, слив, шахта к мойке).
-- Нужны только для проверки скептиком (ev.lua vis=...). В файлы уровней то же правило вписано целиком.
-- Мыло «бесполезно на вид», если оно:
--   (a) смыто;
--   (b) лежит на полу (под ним стена) в «кармане» без выхода: катить его по полу можно только в стену
--       или в слив, а поднять мыло с пола нельзя (толкать вверх нечем — под ним стена);
--   (c) заклинило: ни с одной стороны его не толкнуть (с другой стороны стена, или упор в стену);
-- кроме клеток STEP (низ шахты под мойкой — там мыло и нужно).
-- narrow: проиграно, если бесполезно ВСЁ оставшееся мыло.
-- wide (скептик): ещё и (d) любое заклинившее мыло не на ступеньке — «каждая деталь нужна»;
--       (e) мыло на полке, с которой любой путь вниз кончается на полу без подставки или в сливе.
local M = {}
function M.make(STEPXY, wide, parts)
  parts = parts or (wide and { d = true, e = true } or {})
  return function(lvl, st)
    local W = lvl.W
    local STEP = {}
    for _, p in ipairs(STEPXY) do STEP[(p[2] - 1) * W + p[1]] = true end
    local fixedAt, soapAt, soaps = {}, {}, {}
    for q, p in ipairs(lvl.pieces) do
      local c = st.pos[q]
      if c ~= 0 then
        if st.fixed[q] then fixedAt[c] = true end
        if p.porcelain then soapAt[c] = q; soaps[#soaps + 1] = c end
      end
    end
    if #soaps == 0 then return true end
    local function wall(c) return c == 0 or lvl.cell[c] == 1 or fixedAt[c] end
    local function pit(c) return c ~= 0 and lvl.cell[c] == 2 end
    local function below(c) return lvl.nb[c][3] end
    local function resting(c)
      local b = below(c)
      if wall(b) then return true end
      if soapAt[b] then return resting(b) end
      return false
    end
    local function frozen(c)
      if not resting(c) then return false end -- лежит на Лапидусе: упадёт, когда он уйдёт
      for d = 1, 4 do
        local pc, tc = lvl.nb[c][({ 3, 4, 1, 2 })[d]], lvl.nb[c][d]
        if not wall(pc) and not pit(pc) and not wall(tc) then return false end
      end
      return true
    end
    -- (b): на полу, выхода нет ни влево, ни вправо (только стена или слив), ступеньки на пути нет
    local function pocket(c)
      if not wall(below(c)) then return false end
      for _, d in ipairs({ 2, 4 }) do
        local n = lvl.nb[c][d]
        while n ~= 0 and not wall(n) do
          if STEP[n] then return false end
          local b = below(n)
          if pit(b) then break end
          if not wall(b) and not soapAt[b] then return false end -- край полки: можно уронить ниже
          n = lvl.nb[n][d]
        end
      end
      return true
    end
    local useless
    -- (e): мыло на полке; каждый край полки роняет его на пол без подставки или в слив
    local function doomedShelf(c, depth)
      if depth > 3 or not wall(below(c)) then return false end
      for _, d in ipairs({ 2, 4 }) do
        local n = lvl.nb[c][d]
        while n ~= 0 and not wall(n) do
          if STEP[n] then return false end
          local b = below(n)
          if pit(b) then break end
          if not wall(b) and not soapAt[b] then
            -- падение по столбцу n
            local f = n
            while true do
              local bb = below(f)
              if pit(bb) then break end -- смоет
              if soapAt[bb] then return false end -- есть подставка
              if wall(bb) then
                if STEP[f] then return false end
                if not useless(f, depth + 1) then return false end
                break
              end
              f = bb
            end
            break
          end
          n = lvl.nb[n][d]
        end
      end
      return true
    end
    useless = function(c, depth)
      if STEP[c] then return false end
      if frozen(c) or pocket(c) then return true end
      if parts.e and doomedShelf(c, depth or 0) then return true end
      return false
    end
    if parts.d then
      for _, c in ipairs(soaps) do if not STEP[c] and frozen(c) then return true end end
    end
    for _, c in ipairs(soaps) do if not useless(c, 0) then return false end end
    return true
  end
end
return M
