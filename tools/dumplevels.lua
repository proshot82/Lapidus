-- tools/dumplevels.lua 1 2 3 — уровни в JSON для генераторов арта (функции пропускаются).
local function esc(s) s = s:gsub("\\", "\\\\"); s = s:gsub('"', '\\"'); s = s:gsub("\n", "\\n"); return '"' .. s .. '"' end
local function ser(v)
  local t = type(v)
  if t == "table" then
    if #v > 0 or next(v) == nil then
      local o = {}
      for i = 1, #v do o[#o + 1] = ser(v[i]) end
      return "[" .. table.concat(o, ",") .. "]"
    end
    local o = {}
    for k, x in pairs(v) do if type(x) ~= "function" then o[#o + 1] = esc(tostring(k)) .. ":" .. ser(x) end end
    return "{" .. table.concat(o, ",") .. "}"
  elseif t == "string" then return esc(v)
  elseif t == "number" or t == "boolean" then return tostring(v) end
  return "null"
end
local all = {}
for _, id in ipairs(arg) do all[#all + 1] = dofile(string.format("levels/%02d.lua", tonumber(id))) end
io.write(ser(all))
