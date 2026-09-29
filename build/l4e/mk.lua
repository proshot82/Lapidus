-- build/l4e/mk.lua — генератор файлов кандидатов кв. 4 (раунд 4, три детали) из короткого описания.
-- luajit build/l4e/mk.lua <имя>  → build/l4e/<имя>.lua ; описания — в build/l4e/specs.lua. Решений нет.
local specs = dofile("build/l4e/specs.lua")
local name = arg[1]
local s = assert(specs[name], "нет описания " .. tostring(name))
local function obj(o)
  local parts = {}
  for _, k in ipairs({ "kind", "what", "tag" }) do if o[k] then parts[#parts + 1] = k .. ' = "' .. o[k] .. '"' end end
  if o.at then parts[#parts + 1] = string.format("at = { %d, %d }", o.at[1], o.at[2]) end
  if o.ports then
    local pp = {}
    for _, side in ipairs({ "up", "right", "down", "left" }) do if o.ports[side] then pp[#pp + 1] = side .. ' = "' .. o.ports[side] .. '"' end end
    parts[#parts + 1] = "ports = { " .. table.concat(pp, ", ") .. " }"
  end
  if o.cells then
    local cc = {}
    for _, c in ipairs(o.cells) do cc[#cc + 1] = string.format("{ %d, %d }", c[1], c[2]) end
    parts[#parts + 1] = "cells = { " .. table.concat(cc, ", ") .. " }, head = " .. o.head
  end
  return "    { " .. table.concat(parts, ", ") .. " },"
end
local out = {}
out[#out + 1] = "-- Кв. 4 «Резьба», кандидат " .. name .. " (build/l4e, раунд 4, три детали). " .. (s.comment or "")
out[#out + 1] = "-- Сгенерировано build/l4e/mk.lua из build/l4e/specs.lua. Решение здесь не пишется."
out[#out + 1] = specs.VIS
out[#out + 1] = specs.FILTERS
out[#out + 1] = "return {"
out[#out + 1] = "  visibleLoss = visibleLoss,"
out[#out + 1] = '  id = 4, flat = 4, name = "Резьба",'
out[#out + 1] = string.format("  length = { %d, %d }, pressure = 0, tile = \"mint\",", s.length[1], s.length[2])
out[#out + 1] = "  target = { moves = { 15, 40 }, states = 300000, dead = 40, fb = 2 },"
out[#out + 1] = "  grid = {"
for _, row in ipairs(s.grid) do out[#out + 1] = '    "' .. row .. '",' end
out[#out + 1] = "  },"
out[#out + 1] = "  objects = {"
for _, o in ipairs(s.objects) do out[#out + 1] = obj(o) end
out[#out + 1] = "  },"
out[#out + 1] = s.ablations or specs.ABL
out[#out + 1] = s.controls or specs.CTRL
out[#out + 1] = specs.TEXTS
out[#out + 1] = "}"
local f = assert(io.open("build/l4e/" .. name .. ".lua", "w"))
f:write(table.concat(out, "\n"), "\n")
f:close()
print("build/l4e/" .. name .. ".lua")
