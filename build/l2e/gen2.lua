-- build/l2e/gen2.lua — перебор ступени 2 (шахта x=3..4): положение крюка C, приманки D, портов S/F, ряда лаза; колодец 1 как в e1.
-- Печатает только метрики лучших. luajit build/l2e/gen2.lua [h]
package.path = "./?.lua;" .. package.path
local EV = dofile("build/l2e/ev.lua")
local MK = dofile("build/l2e/mk.lua")
local hRows = { tonumber(arg[1] or 5) }
local part, nparts = tonumber(arg[2] or 0), tonumber(arg[3] or 1)
local function base(h)
  local rows = {}
  for y = 1, 10 do rows[y] = (y == 1 or y == 10) and "###########" or "##..#...###" end
  rows[2] = "#####...12#"
  rows[10] = "##~~#######" -- дно шахты 2 — слив: срыв там смывает (видимо), пол не даёт обхода
  -- лаз (5,h), крюк ряда B (9,h) V, приманка под лазом (5,h+1) V порт вправо
  local function set(y, x, ch) rows[y] = rows[y]:sub(1, x - 1) .. ch .. rows[y]:sub(x + 1) end
  set(h, 5, "."); set(h, 9, "l"); set(h, 10, "#"); set(h + 1, 5, "r")
  for y = 3, h - 1 do set(y, 9, "#") end
  return rows, set
end
local results = {}
local n = 0
for _, h in ipairs(hRows) do
  local portSets = {}
  portSets[#portSets + 1] = { { 3, 2, "S", "down:V" }, { 4, 2, "F", "down:N" } }
  portSets[#portSets + 1] = { { 4, 2, "S", "down:V" }, { 3, 2, "F", "down:N" } }
  portSets[#portSets + 1] = { { 3, 9, "S", "up:V" }, { 4, 9, "F", "up:N" } }
  portSets[#portSets + 1] = { { 4, 9, "S", "up:V" }, { 3, 9, "F", "up:N" } }
  for r = 3, 7 do
    portSets[#portSets + 1] = { { 2, r, "S", "right:V" }, { 2, r + 1, "F", "right:N" } }
    portSets[#portSets + 1] = { { 2, r + 1, "S", "right:V" }, { 2, r, "F", "right:N" } }
  end
  for psi, ps in ipairs(portSets) do if (psi - 1) % nparts == part then
    for cx, cRows in pairs({ [2] = { 3, 4, 5, 6, 7, 8 }, [5] = { 3, 4, 6, 7, 8 } }) do
      for _, cr in ipairs(cRows) do for _, cth in ipairs({ "N", "V" }) do
        for _, d in ipairs({ { 0 }, { 5, 6, "N" }, { 5, 6, "V" }, { 5, 7, "N" }, { 5, 7, "V" }, { 5, 8, "N" }, { 5, 8, "V" }, { 2, 7, "N" }, { 2, 7, "V" }, { 2, 8, "N" }, { 2, 8, "V" } }) do
          local rows, set = base(h)
          local ok = true
          local occ = {}
          local function put(x, y, ch)
            local cur = rows[y]:sub(x, x)
            if occ[y * 20 + x] or (cur ~= "#" and cur ~= ".") then ok = false end
            occ[y * 20 + x] = true; set(y, x, ch)
          end
          -- порты
          for _, p in ipairs(ps) do put(p[1], p[2], p[3]) end
          -- C
          if cx == 5 and (cr == h or cr == h + 1) then ok = false end
          local cch = (cx == 2) and (cth == "N" and "R" or "r") or (cth == "N" and "L" or "l")
          if ok then put(cx, cr, cch) end
          -- D
          if d[1] ~= 0 then
            if d[1] == 5 and (d[2] == h or d[2] == h + 1) then ok = false end
            local dch = (d[1] == 2) and (d[3] == "N" and "R" or "r") or (d[3] == "N" and "L" or "l")
            if ok then put(d[1], d[2], dch) end
          end
          if ok then
            local opts = { len = { 2, 4 } }
            local def = MK.build(rows, opts)
            -- порты: mk ставит S/F с opts.src/fx; здесь задаём вручную
            for _, o in ipairs(def.objects) do
              for _, p in ipairs(ps) do
                if o.at and o.at[1] == p[1] and o.at[2] == p[2] then local dd, t = p[4]:match("^(%a+):(%a)$"); o.ports = { [dd] = t } end
              end
            end
            n = n + 1
            if n % 20 == 0 then io.stderr:write(n .. " ") end
            local r = EV.eval(def, nil, true, true)
            local relax = os.getenv("RELAX")
            if not r.fail and (relax or (r.pctAuthor >= 35 and r.doors1 >= 1 and r.doors2 >= 1 and r.deep >= 8 and r.opt >= 15 and r.nwcfg == 1)) then
              -- крюк C обязан быть нужен решению: без него нерешаем
              local d2 = MK.build(rows, opts)
              for _, o in ipairs(d2.objects) do
                for _, p in ipairs(ps) do if o.at and o.at[1] == p[1] and o.at[2] == p[2] then local dd, t = p[4]:match("^(%a+):(%a)$"); o.ports = { [dd] = t } end end
              end
              local keep = {}
              for _, o in ipairs(d2.objects) do if o.kind == "stub" and o.at[1] == cx and o.at[2] == cr then d2.grid[cr] = d2.grid[cr]:sub(1, cx - 1) .. "#" .. d2.grid[cr]:sub(cx + 1) else keep[#keep + 1] = o end end
              d2.objects = keep
              local r2 = EV.eval(d2, nil, true, true)
              if r2.fail == "unsolvable" then results[#results + 1] = { rows = rows, def = def, r = r, key = string.format("h%d C(%d,%d)%s D(%s) порты %s", h, cx, cr, cth, d[1] == 0 and "-" or (d[1] .. "," .. d[2] .. d[3]), ps[1][1] .. "," .. ps[1][2] .. "/" .. ps[2][1] .. "," .. ps[2][2]) } end
            end
          end
        end
      end end
    end
  end end
end
table.sort(results, function(a, b) return a.r.pctAuthor + a.r.doors1 * 3 > b.r.pctAuthor + b.r.doors1 * 3 end)
print("проверено " .. n .. ", подошло " .. #results)
os.execute("mkdir -p build/l2e/out2")
for i = 1, math.min(12, #results) do
  local x = results[i]; local r = x.r
  print(string.format("%s: ходов %d, скрытых %.0f%% (перев. %.0f%%), глубина %d, двери %d/%d, обезьяна %.2f%%, развилок %d", x.key, r.opt, r.pctAuthor, r.pctFlip, r.deep, r.doors1, r.doors2, r.smart, r.choices))
  local f = io.open(string.format("build/l2e/out2/g%d_p%d_%02d.lua", hRows[1], part, i), "w")
  f:write(MK.dump(x.def, "-- " .. x.key)); f:close()
end
