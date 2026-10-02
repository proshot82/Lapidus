-- build/l7j/scan2.lua файл.lua — перебор старта Лапидуса (длина 2, на опоре) и клетки переходника на полу; метрики met.lua
package.path = "./?.lua;" .. package.path
local MET = dofile("build/l7j/met.lua")
local SV = require("solver.solve")
local base = dofile(arg[1])
local W, H = #base.grid[1], #base.grid
local function free(d, x, y) return d.grid[y] and d.grid[y]:sub(x, x) == "." end
local function occ(d, x, y, skip)
  for _, o in ipairs(d.objects) do if o ~= skip and o.kind ~= "lapidus" and o.at[1] == x and o.at[2] == y then return true end end
end
local adaO, lapO
for _, o in ipairs(base.objects) do if o.tag == "ada" then adaO = o elseif o.kind == "lapidus" then lapO = o end end
local res = {}
for ay = 2, H - 1 do for ax = 2, W - 1 do
  if free(base, ax, ay) and not free(base, ax, ay + 1) and not occ(base, ax, ay, adaO) then
    for y = 2, H - 1 do for x = 2, W - 2 do
      for _, dir in ipairs({ { 1, 0 }, { 0, -1 } }) do
        local x2, y2 = x + dir[1], y + dir[2]
        if free(base, x, y) and free(base, x2, y2) and not occ(base, x, y) and not occ(base, x2, y2)
          and not (x == ax and y == ay) and not (x2 == ax and y2 == ay)
          and (not free(base, x, y + 1) or (x == ax and y + 1 == ay)) then
          for h = 1, 2 do
            local d = SV.deepcopy(base)
            for _, o in ipairs(d.objects) do if o.tag == "ada" then o.at = { ax, ay } elseif o.kind == "lapidus" then o.cells = { { x, y }, { x2, y2 } }; o.head = h end end
            local r = MET.eval(d, 400000)
            if not r.err and r.ncfg == 1 and r.opt >= 24 and r.opt <= 34 and r.deep >= 8 and r.width <= 3 then
              local first = tonumber((r.doorSteps or "99"):match("%d+"))
              if first and first >= 2 then
                print(string.format("A(%d,%d) L(%d,%d)-(%d,%d)h%d ходов %d скр %.1f шир %d прог %d глуб %d двери[%s]", ax, ay, x, y, x2, y2, h, r.opt, r.hid, r.width, r.walk, r.deep, r.doorSteps))
                io.stdout:flush()
              end
            end
          end
        end
      end
    end end
  end
end end
