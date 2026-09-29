-- build/l7v_g/wall2.lua [B] — замуровка групп клеток F38: левые части комнат и их комбинации.
-- Метрики по линейке (A); с аргументом B — плюс правило «деталь на нижнем полу» (build/l7v_g/F38_B.lua).
package.path = "./?.lua;" .. package.path
local L = require("build.l7v_g.lib")
local src = (arg[1] == "B") and "build/l7v_g/F38_B.lua" or "build/l7f/F38.lua"
local function brick(d, cells)
  for _, c in ipairs(cells) do local x, y = c[1], c[2]
    assert(d.grid[y]:sub(x, x) == ".", "не пусто " .. x .. "," .. y)
    d.grid[y] = d.grid[y]:sub(1, x - 1) .. "#" .. d.grid[y]:sub(x + 1) end
  return d
end
local function rect(x1, x2, y1, y2) local t = {} for y = y1, y2 do for x = x1, x2 do t[#t+1] = { x, y } end end return t end
local function cat(...) local t = {} for _, a in ipairs({ ... }) do for _, c in ipairs(a) do t[#t+1] = c end end return t end
local groups = {
  { "база", {} },
  { "верх x2–5", rect(2, 5, 2, 3) },
  { "низ x2–5", rect(2, 5, 5, 7) },
  { "низ x2–4", rect(2, 4, 5, 7) },
  { "низ x2–5 только пол (стр. 7)", rect(2, 5, 7, 7) },
  { "верх x2–5 + низ x2–5", cat(rect(2, 5, 2, 3), rect(2, 5, 5, 7)) },
  { "верх x2–4 + низ x2–4", cat(rect(2, 4, 2, 3), rect(2, 4, 5, 7)) },
}
for _, g in ipairs(groups) do
  local d = brick(dofile(src), g[2])
  local r = L.metrics(d, { abl = true, strict = true })
  print(string.format("%-30s %s", g[1], L.fmt(r))); io.stdout:flush()
end
