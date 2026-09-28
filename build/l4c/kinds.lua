-- build/l4c/kinds.lua файл.lua — из чего состоят скрытые тупики (основная разметка): пара / порядок / кладовка / прочее,
-- и сводка конфигураций деталей среди «прочего». Решений не печатает.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local wide = dofile("build/l4c/vis_wide.lua")
local v3 = dofile("build/l4c/vis_v3.lua")
local qc, qn
for q, p in ipairs(lvl.pieces) do if p.what == "coupling" then qc = q elseif p.what == "nipple" then qn = q end end
local cnt, other = { pair = 0, order = 0, seal = 0, other = 0 }, {}
for i = 1, G.n do
  if G.flag[i] == 0 and good[i] ~= 1 then
    local s = R.decode(lvl, G.keys[i])
    if not def.visibleLoss(lvl, s) then
      local k
      if s.asm[qc] == s.asm[qn] and not s.fixed[qc] then k = "pair"
      elseif wide(lvl, s) then k = "order"
      elseif v3(lvl, s) then k = "seal"
      else k = "other" end
      cnt[k] = cnt[k] + 1
      if k == "other" then
        local t = {}
        for q, p in ipairs(lvl.pieces) do if p.movable then local x, y = R.xy(lvl, s.pos[q]); t[#t + 1] = string.format("%s(%d,%d)%s", p.tag, x, y, s.fixed[q] and "F" or "") end end
        local key = table.concat(t, " ")
        other[key] = (other[key] or 0) + 1
      end
    end
  end
end
print(string.format("скрытые тупики: пара %d, порядок %d, запечатанная кладовка/недоступный тыл %d, прочее %d", cnt.pair, cnt.order, cnt.seal, cnt.other))
for k, v in pairs(other) do print("   прочее: " .. k .. "  — " .. v) end
SV.freeGraph(G); require("ffi").C.free(good)
