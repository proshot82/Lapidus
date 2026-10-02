-- build/l9a/rules9.lua файл.lua [pocket=N] — проверка правил уровня (def.visRules) по отдельности: сколько состояний
-- помечает каждое, сколько из них живых (должно быть 0), сколько скрытых по линейке без правил; доля скрытых без правил,
-- с каждым правилом и со всеми. Только метрики.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local opts = {}
for i = 2, #arg do local k, v = arg[i]:match("^(%w+)=(.+)$"); if k then opts[k] = v end end
if opts.pocket then V.POCKET = tonumber(opts.pocket) end
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local rules = def.visRules or {}
local base = SV.deepcopy(def); base.visibleLoss = nil
local VL0 = V.compute(lvl, G, base, good)
local m0 = V.measure(G, good, VL0.newbie)
print(string.format("линейка без правил уровня: скрытых %.1f %% (карман %d), обезьяна %.3f", m0.hiddenPct, V.POCKET, m0.smart))
local names = {}
for k in pairs(rules) do names[#names+1] = k end
table.sort(names)
local marks = {}
for _, nm in ipairs(names) do
  local f = rules[nm]
  local arr, live, hid, vis = {}, 0, 0, 0
  for i = 1, G.n do if G.flag[i] ~= 2 then
    local st = R.decode(lvl, G.keys[i])
    if f(lvl, st) then arr[i] = true; if good[i] == 1 then live = live + 1 elseif VL0.newbie[i] then vis = vis + 1 else hid = hid + 1 end end
  end end
  marks[nm] = arr
  local comb = {}
  for i = 1, G.n do if G.flag[i] ~= 2 then comb[i] = VL0.newbie[i] or (arr[i] and good[i] ~= 1) or false end end
  local m = V.measure(G, good, comb)
  print(string.format("правило %-6s помечает: живых %d (должно быть 0), скрытых %d, уже видимых %d | линейка+%s: скрытых %.1f %%", nm, live, hid, vis, nm, m.hiddenPct))
end
local VL = V.compute(lvl, G, def, good)
local m = V.measure(G, good, VL.newbie)
print(string.format("все правила: скрытых %.1f %% | обезьяна %.3f | глубина %d у пути [%s]", m.hiddenPct, m.smart, m.maxDeep, m.deepList))
