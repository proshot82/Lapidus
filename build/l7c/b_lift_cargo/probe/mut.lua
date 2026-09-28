-- mut.lua файл.lua — решаемость мутаций кандидата (без решений): без переходника, напор 3, длина 2–5
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local function test(name, f)
  local d = SV.deepcopy(def); d.ablations = nil; f(d)
  local lvl = R.compile(d)
  local G = SV.explore(lvl, 3000000)
  if not G then print(name .. ": CAP") return end
  print(string.format("%s: %s (состояний %d%s)", name, G.firstWin and "решаем" or "нерешаем", G.n, G.firstWin and (", ходов " .. G.depth[G.firstWin]) or ""))
  SV.freeGraph(G)
end
test("без переходника", function(d) local k = {} for _, o in ipairs(d.objects) do if o.tag ~= "adp" then k[#k+1] = o end end d.objects = k end)
test("напор 3", function(d) d.pressure = 3 end)
test("напор 1", function(d) d.pressure = 1 end)
test("длина 2–5", function(d) d.length = { 2, 5 } end)
test("длина 3–4", function(d) d.length = { 3, 4 } end)
