-- g1: F38 с замурованными левыми частями комнат (x=2..5); пол под устьем — видимая потеря (правило §7).
local C = dofile("build/l7f/cand.lua")
local R = require("core.rules")
return C.build{ R = 2, L = { 2, 4 }, rows = {
  "############",
  "#####......#",
  "#####D.w.v.#",
  "#####..#.###",
  "#####......#",
  "#####......#",
  "#####.fHU=S#",
  "############",
}, legend = { U = { kind = "pipe", what = "pipe", ports = { right = "N", up = "V" } },
              S = { kind = "source", ports = { left = "V" } }, ["="] = { kind = "pipe", what = "pipe", ports = { right = "N", left = "V" } },
              D = { kind = "fixture", what = "bath", ports = { down = "V" } } },
  visibleLoss = function(lvl, st)
    for q, p in ipairs(lvl.pieces) do if p.movable and st.pos[q] ~= 0 and not st.fixed[q] then
      local _, y = R.xy(lvl, st.pos[q]); if y == lvl.H - 1 then return true end end end
    return false
  end }
