-- core/search.lua — ограниченный поиск в ширину на том же ядре правил.
-- Игра: «Я в тупике?» (найдено → нет, исчерпано → да, бюджет кончился → не знаю)
-- и «Вызвать мастера» (путь до ближайшей победы). Поиск можно продвигать порциями по кадрам.
local R = require("core.rules")
local tinsert = table.insert
local S = {}

function S.new(lvl, st, budget, filter)
  local k0 = R.key(st)
  local self = {
    lvl = lvl, budget = budget or 200000, filter = filter,
    seen = { [k0] = 1 }, keys = { k0 }, par = { 0 }, mv = { 0 },
    head = 1, done = false, result = nil, path = nil,
  }
  if (not st.dead) and R.isWin(lvl, st) then
    self.done, self.result, self.path = true, "found", {}
  end
  return self
end

local function reconstruct(self, id)
  local path = {}
  while id ~= 1 do
    tinsert(path, 1, self.mv[id])
    id = self.par[id]
  end
  return path
end

-- Раскрыть не больше steps состояний. true — поиск завершён (см. self.result).
function S.step(self, steps)
  if self.done then return true end
  local lvl = self.lvl
  local keys, seen, par, mv = self.keys, self.seen, self.par, self.mv
  local n = 0
  while n < steps do
    if self.head > #keys then
      self.done, self.result = true, "exhausted"
      return true
    end
    if #keys > self.budget then
      self.done, self.result = true, "unknown"
      return true
    end
    local id = self.head
    self.head = id + 1
    n = n + 1
    local cur = R.decode(lvl, keys[id])
    if not cur.dead then
      for m = 1, 8 do
        local M = R.MOVES[m]
        local ns = R.move(lvl, cur, M.which, M.dir)
        if ns and self.filter and not self.filter(lvl, cur, ns) then ns = nil end
        if ns then
          local k = R.key(ns)
          if not seen[k] then
            local nid = #keys + 1
            keys[nid] = k
            seen[k] = nid
            par[nid] = id
            mv[nid] = m
            if (not ns.dead) and R.isWin(lvl, ns) then
              self.done, self.result, self.path = true, "found", reconstruct(self, nid)
              return true
            end
          end
        end
      end
    end
  end
  return false
end

function S.run(lvl, st, budget, filter)
  local s = S.new(lvl, st, budget, filter)
  while not S.step(s, 1000000) do end
  return s.result, s.path, #s.keys
end

return S
