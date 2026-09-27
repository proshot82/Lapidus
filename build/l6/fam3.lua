-- широкий слив под колонкой: без опоры рядом, поднимать можно только «на якоре»
local M = dofile("build/l6/mk.lua")
local out = {}
local function room(leftW, rightW, h, shaft, srcUp, dw, len, th, tag2)
  -- столбец колонки p; слева от слива leftW клеток пола (включая клетку стояка), справа rightW
  local p = 1 + leftW + math.floor(dw / 2) + 1
  local W = 1 + leftW + dw + rightW + 1
  local rows = {}
  rows[1] = string.rep("#", W)
  rows[2] = string.rep("#", p - 1) .. "F" .. string.rep("#", W - p)
  for i = 1, shaft do rows[#rows + 1] = string.rep("#", p - 1) .. (i == 1 and "n" or ".") .. string.rep("#", W - p) end
  for r = 1, h do rows[#rows + 1] = "#" .. string.rep(".", W - 2) .. "#" end
  local bottom = {}
  for x = 1, W do bottom[x] = "#" end
  local d0 = 1 + leftW + 1
  for x = d0, d0 + dw - 1 do bottom[x] = "~" end
  rows[#rows + 1] = table.concat(bottom)
  local H = #rows
  local sx = d0 - 1 -- стояк у левого края слива
  local sy = H - 1 - srcUp
  local r = rows[sy]
  rows[sy] = r:sub(1, sx - 1) .. "S" .. r:sub(sx + 1)
  for yy = sy + 1, H - 1 do local rr = rows[yy]; rows[yy] = rr:sub(1, sx - 1) .. "#" .. rr:sub(sx + 1) end
  local obj
  if th == "B" then
    obj = { F = { kind = "fixture", what = "heater", ports = { down = "N" } }, S = { kind = "source", ports = { right = "N" } },
      n = { kind = "fitting", what = "coupling", tag = "nip", ports = { up = "V", down = "V" } } }
  else
    obj = { F = { kind = "fixture", what = "heater", ports = { down = "V" } }, S = { kind = "source", ports = { right = "V" } },
      n = { kind = "fitting", what = "nipple", tag = "nip", ports = { up = "N", down = "N" } } }
  end
  local d = M.def{ rows = rows, obj = obj, lap = { { 2, H - 1 }, { 2, H - 2 } }, length = len }
  d.tagname = string.format("%s L%dR%d h%d sh%d src+%d dw%d len%d-%d", th, leftW, rightW, h, shaft, srcUp, dw, len[1], len[2])
  d.carry = "nip"; d.startLen = { len[1], math.min(len[2], len[1] + 2) }
  out[#out + 1] = d
end
for _, th in ipairs({ "A" }) do
  for _, lw in ipairs({ 1, 2 }) do
    for _, rw in ipairs({ 1, 2, 3 }) do
      for _, h in ipairs({ 3, 4 }) do
        for _, sh in ipairs({ 1, 2 }) do
          for _, su in ipairs({ 0, 1 }) do
            for _, len in ipairs({ { 3, 5 }, { 2, 5 }, { 3, 6 } }) do
              room(lw, rw, h, sh, su, 3, len, th)
            end
          end
        end
      end
    end
  end
end
return out
