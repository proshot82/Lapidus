-- verify_close.lua файл.lua [vis.lua-файл-уровня-для-классификации] — все ходы, которыми ниппель вкручивается в гнездо:
-- каким концом, из живого ли состояния, где муфта, и куда попадаем (живое / скрытый / видимый тупик).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local def2 = arg[2] and dofile(arg[2]) or def
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local nip, cpl
for q, p in ipairs(lvl.pieces) do if p.tag == "nip" then nip = q elseif p.tag == "cpl" then cpl = q end end
local function lost(d, s)
  for q, p in ipairs(lvl.pieces) do if p.movable and s.pos[q] == 0 then return true end end
  return d.visibleLoss and d.visibleLoss(lvl, s) or false
end
local tab = {}
for i = 1, G.n do if G.flag[i] == 0 and good[i] == 1 then
  local s = R.decode(lvl, G.keys[i])
  if not s.fixed[nip] then
    for m = 1, 8 do
      local mm = R.MOVES[m]
      local ns = R.move(lvl, s, mm.which, mm.dir)
      if ns and ns.fixed[nip] then
        local j = G.index[R.key(ns)]
        local _, cy = R.xy(lvl, ns.pos[cpl])
        local where = (cy >= 5) and "муфта внизу" or "муфта наверху"
        local res = (j and G.flag[j] == 1) and "WIN" or (good[j] == 1 and "живое" or (lost(def2, ns) and "видимый" or "СКРЫТЫЙ"))
        local k = mm.which .. " | " .. where .. " | " .. res
        tab[k] = (tab[k] or 0) + 1
      end
    end
  end
end end
local l = {}
for k, v in pairs(tab) do l[#l+1] = k .. " : " .. v end
table.sort(l); for _, x in ipairs(l) do print(x) end
