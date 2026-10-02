-- «коробка»: узкая комната под колонкой, стояк в нише слева внизу, слив под колонкой
local M = dofile("build/l6/mk.lua")
local out = {}
local function box(bw, bh, shaft, leftOff, srcUp, len, niche)
  -- колонка в столбце hx; комната: столбцы [hx-leftOff .. hx-leftOff+bw-1]
  local hx = 4
  local x0 = hx - leftOff
  local W = x0 + bw + 1
  if x0 - 1 < 2 then return end
  local rows = {}
  rows[1] = string.rep("#", W)
  rows[2] = string.rep("#", hx - 1) .. "F" .. string.rep("#", W - hx)
  for i = 1, shaft do rows[#rows + 1] = string.rep("#", hx - 1) .. (i == 1 and "n" or ".") .. string.rep("#", W - hx) end
  for r = 1, bh do rows[#rows + 1] = string.rep("#", x0 - 1) .. string.rep(".", bw) .. string.rep("#", W - x0 - bw + 1) end
  rows[#rows + 1] = string.rep("#", hx - 1) .. "~" .. string.rep("#", W - hx)
  local H = #rows
  -- стояк в нише слева от комнаты: (x0-1, H-1-srcUp)
  local sy = H - 1 - srcUp
  local r = rows[sy]
  rows[sy] = r:sub(1, x0 - 2) .. "S" .. r:sub(x0)
  local obj = { F = { kind = "fixture", what = "heater", ports = { down = "V" } }, S = { kind = "source", ports = { right = "V" } },
    n = { kind = "fitting", what = "nipple", tag = "nip", ports = { up = "N", down = "N" } } }
  local d = M.def{ rows = rows, obj = obj, lap = { { x0, H - 1 }, { x0 + 1, H - 1 } }, length = len }
  d.tagname = string.format("box%dx%d sh%d off%d src+%d L%d-%d", bw, bh, shaft, leftOff, srcUp, len[1], len[2])
  d.carry = "nip"; d.startLen = { len[1], len[2] }
  out[#out + 1] = d
end
for _, bw in ipairs({ 3, 4, 5 }) do
  for _, bh in ipairs({ 3, 4, 5 }) do
    for _, sh in ipairs({ 1, 2 }) do
      for _, off in ipairs({ 0, 1, 2 }) do
        if off < bw then
          for _, su in ipairs({ 0, 1 }) do
            for _, len in ipairs({ { 3, 5 }, { 3, 6 } }) do box(bw, bh, sh, off, su, len) end
          end
        end
      end
    end
  end
end
return out
