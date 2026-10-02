-- build/l9j/bear.lua файл — «несущность»: как меняется уровень, если запретить каждую ошибку плана фильтром.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local E = dofile("build/l9j/eval.lua")
local function tagOf(lvl, tag) for q, p in ipairs(lvl.pieces) do if p.tag == tag then return q end end end
local filters = {
  ["без ошибок"] = nil,
  ["запрет: заглушка на свободном тройнике"] = function(lvl, st, ns)
    local t, p = tagOf(lvl, "tee"), tagOf(lvl, "plug")
    return not (not ns.fixed[t] and ns.pos[t] ~= 0 and ns.pos[p] ~= 0 and ns.asm[t] == ns.asm[p])
  end,
  ["запрет: тройник на стояке"] = function(lvl, st, ns)
    local t = tagOf(lvl, "tee")
    local src; for q, pp in ipairs(lvl.pieces) do if pp.source then src = q end end
    return not (ns.fixed[t] and ns.pos[t] == lvl.nb[lvl.pieces[src].start][R.UP])
  end,
}
for name, f in pairs(filters) do
  local def = dofile(arg[1]); def._filter = f
  local r = E.eval(def, 3000000, true)
  print(string.format("%-42s ходов %d, состояний %d, скрытых %.0f %%, обезьяна %.3f %%, двери %d/%d, глубина %d", name, r.opt, r.n, r.hidPct, r.smart, r.doors1, r.doors2, r.maxDeep))
end
local def = dofile(arg[1])
local fa, fb = filters["запрет: заглушка на свободном тройнике"], filters["запрет: тройник на стояке"]
def._filter = function(l, s, n) return fa(l, s, n) and fb(l, s, n) end
local r = E.eval(def, 3000000, true)
print(string.format("%-42s ходов %d, состояний %d, скрытых %.0f %%, обезьяна %.3f %%, двери %d/%d, глубина %d", "запрет обеих", r.opt, r.n, r.hidPct, r.smart, r.doors1, r.doors2, r.maxDeep))
