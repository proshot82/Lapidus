-- mk.lua — сборка определения уровня из ASCII-раскладки (для быстрой ручной правки кандидатов).
-- local MK = dofile("build/l7c/d_tee_lift/mk.lua")
-- local def = MK.build{ rows = { "#####", ... }, legend = { S = {kind="source", ports={right="V"}}, ... },
--                       lap = "fo H" (порядок не нужен: тело — клетки f,o,H, путь ищется сам), R = 3, L = {2,5} }
-- Символы: # стена, ~ слив, . пусто; буквы из legend — объекты (регистр не важен для поиска в legend: берётся как есть);
-- f — ноги Лапидуса, H — голова, o — звенья тела (тело должно быть простой цепочкой от f к H).
local M = {}

function M.build(t)
  local rows = t.rows
  local grid, objects = {}, {}
  local f, h, body = nil, nil, {}
  for y, row in ipairs(rows) do
    local g = {}
    for x = 1, #row do
      local ch = row:sub(x, x)
      if ch == "#" or ch == "~" or ch == "." then g[#g + 1] = ch
      else
        g[#g + 1] = "."
        if ch == "f" then f = { x, y }
        elseif ch == "H" then h = { x, y }
        elseif ch == "o" then body[#body + 1] = { x, y }
        else
          local L = assert(t.legend[ch], "нет в легенде: " .. ch)
          local o = {}
          for k, v in pairs(L) do o[k] = v end
          o.at = { x, y }
          if o.kind == "fitting" or o.kind == "porcelain" then o.tag = o.tag or ch end
          objects[#objects + 1] = o
        end
      end
    end
    grid[y] = table.concat(g)
  end
  -- путь тела от f к H
  assert(f and h, "нет ног или головы")
  local cells = { f }
  local used = { [f[1] .. "," .. f[2]] = true }
  local cur = f
  while not (cur[1] == h[1] and cur[2] == h[2]) do
    local nxt
    for _, c in ipairs(body) do
      if not used[c[1] .. "," .. c[2]] and math.abs(c[1] - cur[1]) + math.abs(c[2] - cur[2]) == 1 then nxt = c end
    end
    if not nxt and math.abs(h[1] - cur[1]) + math.abs(h[2] - cur[2]) == 1 then nxt = h end
    assert(nxt, "тело не цепочка")
    used[nxt[1] .. "," .. nxt[2]] = true
    cells[#cells + 1] = nxt
    cur = nxt
  end
  objects[#objects + 1] = { kind = "lapidus", cells = cells, head = #cells }
  local def = {
    id = 7, flat = 7, name = "Дали напор",
    length = t.L or { 2, 5 }, pressure = t.R or 3,
    grid = grid, objects = objects,
  }
  return def
end
return M
