-- build/l8v/aim.lua файл.lua — скептик кв. 8: карта прицела брандспойта. Для каждого порта стояка/прибора и каждого конца,
-- который к нему подходит по резьбе, перебираются все тела длины Lmin..Lmax (самонепересекающиеся, по пустым клеткам,
-- без учёта подвижных деталей) и печатается, какие клетки накрывает струя свободного конца (напор R) и откуда.
-- Плюс: клетки, которых тело достаёт само (с якоря), — чтобы видеть зону «только струя».
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local def = dofile(arg[1])
local lvl = R.compile(def)
local W, H = lvl.W, lvl.H
local occ = {}
for q, p in ipairs(lvl.pieces) do if not p.movable then occ[p.start] = q end end
local function free(c) return c ~= 0 and lvl.cell[c] == R.EMPTY and not occ[c] end
for q, p in ipairs(lvl.pieces) do
  if not p.movable then
    for d = 1, 4 do
      local th = p.ports[d]
      if th then
        local c0 = lvl.nb[p.start][d]
        if free(c0) then
          local which = (th == "V") and "ноги(Н)" or "голова(В)"
          -- тело: b[1] = c0 (якорный конец), b[2] = шея = c0 + d (по оси порта), дальше свободно
          local neck = lvl.nb[c0][d]
          local jetMap, bodyMap, origin = {}, {}, {}
          local function rec(body, used)
            local n = #body
            if n >= lvl.Lmin then
              local e, pre = body[n], body[n - 1]
              local dir = R.dirBetween(lvl, pre, e)
              local t = e
              for _ = 1, lvl.R do
                t = lvl.nb[t][dir]
                if t == 0 or lvl.cell[t] == R.WALL or occ[t] or used[t] then break end
                jetMap[t] = true
                origin[t] = origin[t] or {}
                local ex, ey = R.xy(lvl, e); origin[t][ex .. "," .. ey .. R.DIRNAME[dir]:sub(1,1)] = true
              end
            end
            if n < lvl.Lmax then
              for dd = 1, 4 do
                local t = lvl.nb[body[n]][dd]
                if free(t) and not used[t] then
                  used[t] = true; body[n + 1] = t; bodyMap[t] = true
                  rec(body, used)
                  body[n + 1] = nil; used[t] = nil
                end
              end
            end
          end
          if free(neck) then
            local used = { [c0] = true, [neck] = true }
            bodyMap[c0], bodyMap[neck] = true, true
            rec({ c0, neck }, used)
          end
          local px, py = p.x, p.y
          print(string.format("== якорь: %s %s порт %s (%s) — %s у (%d,%d); свободный конец бьёт (* — только струя, тело не достаёт; o — тело; + — струя и тело)",
            p.kind, p.what or "", R.DIRNAME[d], th, which, px, py))
          for y = 1, H do
            local row = {}
            for x = 1, W do
              local c = R.idx(lvl, x, y)
              local ch = lvl.cell[c] == R.WALL and "#" or (occ[c] and "S" or ".")
              if jetMap[c] and bodyMap[c] then ch = "+" elseif jetMap[c] then ch = "*" elseif bodyMap[c] then ch = "o" end
              if c == p.start then ch = "@" end
              row[#row + 1] = ch
            end
            print("  " .. table.concat(row))
          end
          local only = {}
          for c in pairs(jetMap) do if not bodyMap[c] then local x, y = R.xy(lvl, c); local o = {}; for k in pairs(origin[c]) do o[#o+1] = k end; table.sort(o); only[#only + 1] = string.format("(%d,%d)←{%s}", x, y, table.concat(o, " ")) end end
          table.sort(only)
          print("  только струя: " .. (#only > 0 and table.concat(only, " ") or "нет"))
        end
      end
    end
  end
end
