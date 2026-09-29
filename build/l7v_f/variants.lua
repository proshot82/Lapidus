-- build/l7v_f/variants.lua — варианты E17 без пары (одна заглушка Н) и перестановки деталей: нужна ли третья деталь.
package.path = "./?.lua;" .. package.path
local L = require("build.l7v_f.lib")
local P = "build/l7e/E17.lua"
local function drop(d, tag) for i, o in ipairs(d.objects) do if o.tag == tag then table.remove(d.objects, i) return end end end
local function get(d, tag) for _, o in ipairs(d.objects) do if o.tag == tag then return o end end end
local V = {
  { "база", function(d) end },
  { "без ниппеля, заглушка Н на месте заглушки", function(d) drop(d, "nip"); get(d, "plug").ports = { left = "N" } end },
  { "без ниппеля, заглушка Н на месте ниппеля", function(d) drop(d, "nip"); local p = get(d, "plug"); p.ports = { left = "N" }; p.at = { 3, 5 } end },
  { "без заглушки, ниппель→заглушка Н (на месте ниппеля)", function(d) drop(d, "plug"); get(d, "nip").ports = { left = "N" } end },
  { "ниппель и заглушка поменяны местами", function(d) local a, b = get(d, "nip"), get(d, "plug"); a.at, b.at = b.at, a.at end },
}
for _, v in ipairs(V) do
  local d = dofile(P); v[2](d)
  local r = L.metrics(d, { abl = true })
  print(v[1] .. ": " .. L.fmt(r)); io.stdout:flush()
end
