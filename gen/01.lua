-- Скелет уровня 1 «Не той стороной»: лежит задом наперёд, развернуться — только повиснув на чужой резьбе.
local function ends(d) for _, o in ipairs(d.objects) do if o.kind == "lapidus" then return o.cells[1], o.cells[#o.cells] end end end
return {
  id = 1, flat = 1, name = "Не той стороной",
  length = { 2, 4 }, pressure = 0,
  target = { moves = { 18, 30 }, states = 20000, dead = 25, fb = 1 },
  wallProb = 0.25, drainProb = 0.3,
  grid = { "##########", "#????????#", "#????????#", "#????????#", "#????????#", "#????????#", "#????????#" },
  objects = {
    { kind = "source", area = { 2, 2, 5, 6 }, portsOptions = { { right = "N" }, { up = "N" }, { down = "N" } } },
    { kind = "fixture", what = "sink", area = { 4, 2, 9, 6 }, portsOptions = { { left = "V" }, { up = "V" }, { down = "V" } } },
    { kind = "stub", tag = "hook", area = { 2, 2, 9, 5 }, portsOptions = { { down = "N" }, { left = "N" }, { right = "N" } } },
  },
  lapidus = { area = { 2, 2, 9, 6 }, len = { 2, 3 } },
  near = { 1, 2, 5 },
  ablations = { { name = "у крюка чужая резьба", flip = "hook" } },
  accept = function(d) local heel, head = ends(d); return head[1] > heel[1] end,
}
