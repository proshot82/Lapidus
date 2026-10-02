-- build/l3v3/headpush.lua [файл] — самобытность M8: если голове РАЗРЕШИТЬ толкать фаянс, что меняется?
package.path = "./?.lua;" .. package.path
local src = assert(io.open("core/rules.lua")):read("*a")
local src2, n = src:gsub('if which == "head" and lvl%.pieces%[q%]%.porcelain then return nil, "soap" end', "")
assert(n == 1, "строка правила M8 не найдена")
package.loaded["core.rules"] = assert(load(src2, "=rules_headpush"))()
local L = dofile("build/l3v3/lib.lua")
local path = arg[1] or "levels/03.lua"
local def = dofile(path)
print("голова толкает фаянс: " .. L.fmt(L.metrics(def)))
local a = L.SV.ablations(def, { cap = 3000000 }); local s = {}
for _, e in ipairs(a) do s[#s + 1] = e.name .. "=" .. (e.solvable == false and "нерешаем" or "РЕШАЕМ") end
print("абляции при толкающей голове: " .. table.concat(s, ", "))
local ST = require("solver.strict")
local sx = ST.check(def, 3000000)
if sx then print(string.format("строго: наобум %.3f %%, кратчайших %d, ширина %d", sx.monkey, sx.shortest, sx.maxWidth)) end
-- и обратная асимметрия: только голова толкает, ноги — нет
