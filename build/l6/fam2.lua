local M = dofile("build/l6/mk.lua")
local out = {}
local function room(w, h, shaft, srcUp, len, extra, th)
  local W = 1 + w + 1
  local rows = {}
  rows[1] = string.rep("#", W)
  local hx = 4
  rows[2] = string.rep("#", hx - 1) .. "F" .. string.rep("#", W - hx)
  for i = 1, shaft do rows[#rows + 1] = string.rep("#", hx - 1) .. (i == 1 and "n" or ".") .. string.rep("#", W - hx) end
  for r = 1, h do rows[#rows + 1] = "#" .. string.rep(".", w) .. "#" end
  rows[#rows + 1] = string.rep("#", hx - 1) .. "~" .. string.rep("#", W - hx)
  local H = #rows
  local sy = H - 1 - srcUp
  local r = rows[sy]
  rows[sy] = r:sub(1, hx - 3) .. "S" .. r:sub(hx - 1)
  for yy = sy + 1, H - 1 do local rr = rows[yy]; rows[yy] = rr:sub(1, hx - 3) .. (extra == "hang" and "." or "#") .. rr:sub(hx - 1) end
  local obj
  if th == "B" then
    obj = {
      F = { kind = "fixture", what = "heater", ports = { down = "N" } },
      S = { kind = "source", ports = { right = "N" } },
      n = { kind = "fitting", what = "coupling", tag = "nip", ports = { up = "V", down = "V" } },
    }
  else
    obj = {
      F = { kind = "fixture", what = "heater", ports = { down = "V" } },
      S = { kind = "source", ports = { right = "V" } },
      n = { kind = "fitting", what = "nipple", tag = "nip", ports = { up = "N", down = "N" } },
    }
  end
  local d = M.def{ rows = rows, obj = obj, lap = { { hx, H - 1 }, { hx + 1, H - 1 } }, length = len }
  d.tagname = string.format("%s w%d h%d sh%d src+%d L%d-%d %s", th, w, h, shaft, srcUp, len[1], len[2], extra or "")
  d.carry = "nip"; d.startLen = { len[1], math.min(len[2], len[1] + 2) }
  out[#out + 1] = d
end
for _, th in ipairs({ "A", "B" }) do
for _, w in ipairs({ 4, 5 }) do
  for _, h in ipairs({ 3, 4 }) do
    for _, sh in ipairs({ 1, 2 }) do
      for _, su in ipairs({ 1, 2 }) do
        if su < h then
          for _, len in ipairs({ { 3, 5 }, { 2, 5 } }) do
            room(w, h, sh, su, len, nil, th)
            room(w, h, sh, su, len, "hang", th)
          end
        end
      end
    end
  end
end
end
return out
