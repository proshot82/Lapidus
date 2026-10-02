-- build/l6/mk.lua — сборка черновика уровня из ASCII: буквы объектов в сетке, порты — в таблице.
-- Буквы: S стояк, F прибор, T глухой отвод, P труба(закреплённая), a..e подвижные детали, p фаянс.
-- Лапидус: lap = { {x,y}, ... } от ног к голове.
local M = {}
function M.def(t)
  local grid, objects = {}, {}
  for y, row in ipairs(t.rows) do
    local g = {}
    for x = 1, #row do
      local ch = row:sub(x, x)
      if ch == "#" or ch == "." or ch == "~" then g[#g + 1] = ch
      else
        g[#g + 1] = "."
        local spec = assert(t.obj[ch], "no spec for " .. ch)
        local o = { at = { x, y } }
        for k, v in pairs(spec) do
          if k == "ports" then o.ports = {}; for s, th in pairs(v) do o.ports[s] = th end else o[k] = v end
        end
        objects[#objects + 1] = o
      end
    end
    grid[y] = table.concat(g)
  end
  local cells = {}
  for i, c in ipairs(t.lap) do cells[i] = { c[1], c[2] } end
  objects[#objects + 1] = { kind = "lapidus", cells = cells, head = #cells }
  return {
    id = 6, flat = 6, name = t.name or "Намертво", length = t.length or { 3, 5 }, pressure = 0,
    target = t.target or { moves = { 15, 70 }, states = 1000000, dead = 40, fb = 1 },
    grid = grid, objects = objects, ablations = t.ablations or {}, tile = "mustard",
  }
end
-- фильтр «кран запрещён»: ни одна деталь не может оказаться выше, чем была до хода
function M.noLift(lvl, st, ns)
  local W = lvl.W
  for q = 1, #st.pos do
    local a, b = st.pos[q], ns.pos[q]
    if a ~= 0 and b ~= 0 and math.floor((b - 1) / W) < math.floor((a - 1) / W) then return false end
  end
  return true
end
return M
