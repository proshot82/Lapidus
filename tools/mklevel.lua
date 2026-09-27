-- tools/mklevel.lua кандидат.lua уровень.lua tile — переносит кандидата мутатора в levels/ с текстами.
local d = dofile(arg[1])
d.tile = arg[3]
d.texts = {
  request = "Гора посуды. Воды нет. Гора растёт.",
  hints = {
    "Фаянс толкают только ноги, а ноги нужны у стояка. Всё решает очерёдность ролей.",
    "Ваш звонок очень важен для нас. Проверяем, не завязли ли вы.",
    "Мастер выехал. Посуду он не моет.",
  },
}
local function key(k)
  if type(k) == "string" and k:match("^[%a_][%w_]*$") then return k end
  return "[" .. (type(k) == "string" and string.format("%q", k) or tostring(k)) .. "]"
end
local function lser(v, ind)
  local t = type(v)
  if t == "string" then return string.format("%q", v) end
  if t ~= "table" then return tostring(v) end
  local nx, parts, ks = #v, {}, {}
  for i = 1, nx do parts[#parts + 1] = lser(v[i], ind .. "  ") end
  for k in pairs(v) do if not (type(k) == "number" and k >= 1 and k <= nx and k % 1 == 0) then ks[#ks + 1] = k end end
  table.sort(ks, function(a, b) return tostring(a) < tostring(b) end)
  for _, k in ipairs(ks) do if type(v[k]) ~= "function" then parts[#parts + 1] = key(k) .. " = " .. lser(v[k], ind .. "  ") end end
  local one = "{ " .. table.concat(parts, ", ") .. " }"
  if #one < 90 then return one end
  return "{\n" .. ind .. "  " .. table.concat(parts, ",\n" .. ind .. "  ") .. ",\n" .. ind .. "}"
end
local f = assert(io.open(arg[2], "w"))
f:write("-- Квартира " .. d.flat .. " «" .. d.name .. "». Раскладка найдена мутатором на авторском скелете и проверена солвером.\nreturn " .. lser(d, "") .. "\n")
f:close()
