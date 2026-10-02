-- logrows.lua "файл|замысел" ... — строки таблицы LOG.md (метрики + проваленные ворота). Только метрики.
package.path = "./?.lua;" .. package.path
local Q = dofile("build/l6c/b_wall_forever/quick.lua")
for _, a in ipairs(arg) do
  local f, idea = a:match("^(.-)|(.*)$")
  local ok, def = pcall(dofile, f)
  local name = f:match("([^/]+)%.lua$")
  if not ok then print("| " .. name .. " | " .. idea .. " | ошибка загрузки | — |") else
    local m = Q.metrics(def, 2000000)
    if m.err or m.unsolv then print("| " .. name .. " | " .. idea .. " | " .. Q.line(m) .. " | не решается |") else
      local fail = {}
      if m.hidpct < 40 then fail[#fail + 1] = "скрытые" end
      if m.smart > 0.2 then fail[#fail + 1] = "обезьяна" end
      if m.deep < 8 then fail[#fail + 1] = "глубина" end
      if m.walk > 6 then fail[#fail + 1] = "прогулка" end
      if m.width > 3 then fail[#fail + 1] = "ширина" end
      if m.opt < 15 or m.opt > 40 then fail[#fail + 1] = "длина" end
      if m.nwin ~= 1 then fail[#fail + 1] = "выигрышей " .. m.nwin end
      print(string.format("| %s | %s | %d ходов, %d сост., скрытых %.1f %%, обезьяна %.2f %%, глубина %d, прогулка %d, событий %d, кратчайших %d/%d | %s |",
        name, idea, m.opt, m.n, m.hidpct, m.smart, m.deep, m.walk, m.events, m.nshort, m.width, #fail > 0 and table.concat(fail, ", ") or "все посчитанные пройдены"))
    end
  end
end
