package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local F = dofile("build/l6/roles.lua")
for _, path in ipairs(arg) do
  local def = dofile(path)
  local lvl = R.compile(def)
  local out = {}
  for _, name in ipairs({ "noDrop", "noLift", "noHeelLift" }) do
    local G = SV.explore(lvl, 3000000, F[name])
    out[#out + 1] = name .. "=" .. (G.firstWin and ("решаем за " .. G.depth[G.firstWin]) or "нерешаем")
    SV.freeGraph(G)
  end
  print(path .. ": " .. table.concat(out, ", "))
end
