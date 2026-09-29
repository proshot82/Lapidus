-- build/l4v2/controls.lua — контрольные варианты k40 (без ходов).
package.path = "./?.lua;" .. package.path
local SV = require("solver.solve")
local MT = dofile("build/l4v2/metrics.lua")
local def0 = dofile(arg[1] or "build/l4d/k40.lua")
local function var(name, f)
  local d = SV.deepcopy(def0); f(d)
  io.write(string.format("%-58s %s\n", name .. ":", MT.fmt(MT.run(d)))); io.flush()
end
local function obj(d, tag) for _, o in ipairs(d.objects) do if o.tag == tag then return o end end end
var("исходный", function(d) end)
var("длина 2–3", function(d) d.length = { 2, 3 } end)
var("длина 2–5 (мост из Лапидуса над машинкой?)", function(d) d.length = { 2, 5 } end)
var("длина 3–4", function(d) d.length = { 3, 4 } end)
var("детали поменяны местами", function(d) obj(d, "cpl").at = { 7, 3 }; obj(d, "nip").at = { 5, 3 } end)
var("муфта сразу в коридоре (6,6)", function(d) obj(d, "cpl").at = { 6, 6 } end)
var("муфта сразу у входа (8,6)", function(d) obj(d, "cpl").at = { 8, 6 } end)
var("ниппель левее люка на антресоли (4,3)?", function(d) obj(d, "nip").at = { 3, 3 } end)
var("муфта правее, ниппель у края (6,2)/(7,3)", function(d) obj(d, "cpl").at = { 6, 2 } end)
