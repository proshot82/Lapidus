-- tools/probe.lua — быстрый прогон кандидатов: метрики, абляции. Решения не печатает.
-- luajit tools/probe.lua файл.lua [cap]   (файл возвращает список уровней)
package.path = "./?.lua;" .. package.path
local SV = require("solver.solve")
local ST = require("solver.strict")
local list = dofile(arg[1])
local cap = tonumber(arg[2] or "2000000")
for _, def in ipairs(list) do
  local res = SV.analyze(def, { cap = cap })
  local abl = SV.ablations(def, { cap = cap })
  local ab = {}
  for _, a in ipairs(abl) do ab[#ab + 1] = a.name .. "=" .. (a.solvable == false and "нет" or tostring(a.solvable)) end
  local T = def.target or {}
  print(string.format("%-14s %s | abl: %s | T: %s–%s ходов, ≤%s, ≥%s%%, ≥%s",
    def.tagname or def.name, SV.summary(res), table.concat(ab, ", "),
    T.moves and T.moves[1] or "?", T.moves and T.moves[2] or "?", T.states or "?", T.dead or "?", T.fb or "?"))
  local sx = res.solvable and ST.check(def, 400000) or nil
  if sx then print(string.format("  строго: наобум %.2f %% за 1000 ходов; кратчайших вариантов %d (ширина до %d, развилок %d)", sx.monkey, sx.shortest, sx.maxWidth, sx.spread)) end
  if #(res.errors or {}) > 0 then print("  errors: " .. table.concat(res.errors, "; ")) end
  if #(res.warnings or {}) > 0 then print("  warnings: " .. table.concat(res.warnings, "; ")) end
end
