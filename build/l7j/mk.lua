-- build/l7j/mk.lua: генератор кандидата из короткой спецификации (grid + объекты). luajit build/l7j/mk.lua spec.lua out.lua
local spec = dofile(arg[1])
local out = { "-- l7j кандидат " .. (spec.name or "") .. " (сгенерировано build/l7j/mk.lua). Решение не пишется.",
  'local okV, vis = pcall(dofile, "build/l6j/vis.lua")',
  "return {", "  visibleLoss = okV and vis or nil,",
  string.format('  id = 7, flat = 7, name = %q,', spec.name or "l7j"),
  string.format("  length = { %d, %d }, pressure = 0, tile = \"mint\",", spec.L[1], spec.L[2]),
  "  target = { moves = { 15, 40 }, states = 100000, dead = 40, fb = 2 },", "  grid = {" }
for _, r in ipairs(spec.grid) do out[#out+1] = string.format("    %q,", r) end
out[#out+1] = "  },"
out[#out+1] = "  objects = {"
for _, o in ipairs(spec.objects) do out[#out+1] = "    " .. o .. "," end
out[#out+1] = "  },"
out[#out+1] = "  ablations = {"
for _, a in ipairs(spec.ablations or {}) do out[#out+1] = "    " .. a .. "," end
out[#out+1] = "  },"
out[#out+1] = '  texts = { request = "", hints = { "", "", "" } },'
out[#out+1] = "}"
local f = assert(io.open(arg[2], "w")); f:write(table.concat(out, "\n"), "\n"); f:close()
