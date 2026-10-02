-- build/l2k/abl.lua — абляции кандидата: каждый крюк замурован (клетка → стена, геометрия та же, резьбы нет) и убран;
-- деталь убрана. Использование: ablations = dofile("build/l2k/abl.lua")({ "hook", "hook2" }, { "cpl" })
return function(hooks, pieces)
  local out = {}
  for _, tag in ipairs(hooks) do
    out[#out + 1] = { name = "крюк " .. tag .. " замурован", mutate = function(d)
      local k = {}
      for _, o in ipairs(d.objects) do
        if o.tag == tag then local r = d.grid[o.at[2]]; d.grid[o.at[2]] = r:sub(1, o.at[1] - 1) .. "#" .. r:sub(o.at[1] + 1)
        else k[#k + 1] = o end
      end
      d.objects = k
    end }
    out[#out + 1] = { name = "без крюка " .. tag, remove = tag }
  end
  for _, tag in ipairs(pieces) do out[#out + 1] = { name = "без детали " .. tag, remove = tag } end
  -- роль крюка: висеть на нём нельзя (резьба есть, муфта к нему прикручивается, но конец Лапидуса — нет)
  out[#out + 1] = { name = "висеть на крюке нельзя", filter = function(lvl, st, ns)
    local R = require("core.rules")
    local piece = R.occupancy(ns)
    for _, w in ipairs({ "head", "heel" }) do
      local q = R.endScrew(lvl, ns, piece, w)
      if q and lvl.pieces[q].kind == "stub" then return false end
    end
    return true
  end }
  return out
end
