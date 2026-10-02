-- build/l2d/mk.lua — сборка def уровня из ASCII с буквами объектов (для быстрых проб; решений не содержит).
-- Буквы: S стояк, F прибор (унитаз); крючья-отводы: R/r порт вправо, L/l влево, U/u вверх, D/d вниз
-- (заглавная — резьба Н, строчная — В); деталь: c муфта В/В горизонтальная, C ниппель Н/Н горизонтальный,
-- o муфта В/В вертикальная, O ниппель Н/Н вертикальный; Лапидус: цифры 1..4 (1 — ноги, старшая — голова).
-- local MK = dofile("build/l2d/mk.lua"); def = MK.build(rows, { src = "right:V", fx = "left:N", len = {2,4} })
local M = {}

local HOOK = { R = { "right", "N" }, r = { "right", "V" }, L = { "left", "N" }, l = { "left", "V" },
               U = { "up", "N" }, u = { "up", "V" }, D = { "down", "N" }, d = { "down", "V" } }
local FIT = {
  c = { what = "coupling", ports = { left = "V", right = "V" } },
  C = { what = "nipple", ports = { left = "N", right = "N" } },
  o = { what = "coupling", ports = { up = "V", down = "V" } },
  O = { what = "nipple", ports = { up = "N", down = "N" } },
}

function M.build(rows, o)
  o = o or {}
  local grid, objects, lap = {}, {}, {}
  local function port(s) local d, t = s:match("^(%a+):(%a)$"); return { [d] = t } end
  local hookN = 0
  for y, row in ipairs(rows) do
    local out = {}
    for x = 1, #row do
      local ch = row:sub(x, x)
      local g = "."
      if ch == "#" or ch == "~" then g = ch
      elseif ch == "S" then objects[#objects + 1] = { kind = "source", at = { x, y }, ports = port(o.src or "right:V") }
      elseif ch == "F" then objects[#objects + 1] = { kind = "fixture", what = o.what or "toilet", at = { x, y }, ports = port(o.fx or "left:N") }
      elseif HOOK[ch] then
        hookN = hookN + 1
        objects[#objects + 1] = { kind = "stub", tag = "h" .. hookN, at = { x, y }, ports = { [HOOK[ch][1]] = HOOK[ch][2] } }
      elseif FIT[ch] then
        objects[#objects + 1] = { kind = "fitting", what = FIT[ch].what, tag = "cpl", at = { x, y }, ports = FIT[ch].ports }
      elseif ch:match("%d") then lap[tonumber(ch)] = { x, y }
      elseif ch ~= "." then error("bad char " .. ch) end
      out[#out + 1] = g
    end
    grid[y] = table.concat(out)
  end
  local cells = {}
  for i = 1, 4 do if lap[i] then cells[#cells + 1] = lap[i] end end
  assert(#cells >= 2, "lapidus needs >= 2 cells")
  objects[#objects + 1] = { kind = "lapidus", cells = cells, head = #cells }
  return {
    id = 2, flat = 2, name = "Скалолаз", length = o.len or { 2, 4 }, pressure = 0, tile = "blue",
    target = { moves = { 15, 40 }, states = 50000, dead = 40, fb = 2 },
    grid = grid, objects = objects, visibleLoss = o.visibleLoss, ablations = o.ablations,
    texts = o.texts,
  }
end

-- печать def как файла уровня (полный формат)
function M.dump(def, header, extra)
  local t = { header or "", "return {" }
  t[#t + 1] = string.format('  id = %d, flat = %d, name = "%s",', def.id, def.flat, def.name)
  t[#t + 1] = string.format('  length = { %d, %d }, pressure = %d, tile = "%s",', def.length[1], def.length[2], def.pressure, def.tile)
  t[#t + 1] = '  target = { moves = { 15, 40 }, states = 50000, dead = 40, fb = 2 },'
  t[#t + 1] = "  grid = {"
  for _, r in ipairs(def.grid) do t[#t + 1] = '    "' .. r .. '",' end
  t[#t + 1] = "  },"
  t[#t + 1] = "  objects = {"
  for _, ob in ipairs(def.objects) do
    if ob.kind == "lapidus" then
      local cs = {}
      for _, c in ipairs(ob.cells) do cs[#cs + 1] = string.format("{ %d, %d }", c[1], c[2]) end
      t[#t + 1] = string.format("    { kind = \"lapidus\", cells = { %s }, head = %d },", table.concat(cs, ", "), ob.head)
    else
      local ps = {}
      for _, d in ipairs({ "up", "right", "down", "left" }) do if ob.ports[d] then ps[#ps + 1] = d .. ' = "' .. ob.ports[d] .. '"' end end
      t[#t + 1] = string.format("    { kind = \"%s\",%s%s at = { %d, %d }, ports = { %s } },", ob.kind,
        ob.what and (' what = "' .. ob.what .. '",') or "", ob.tag and (' tag = "' .. ob.tag .. '",') or "", ob.at[1], ob.at[2], table.concat(ps, ", "))
    end
  end
  t[#t + 1] = "  },"
  if extra then t[#t + 1] = extra end
  t[#t + 1] = "}"
  return table.concat(t, "\n") .. "\n"
end

return M
