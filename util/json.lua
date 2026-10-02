-- util/json.lua — минимальный JSON без зависимостей (ключи объектов сортируются).
local J = {}
local ESC = { ['"'] = '\\"', ['\\'] = '\\\\', ['\n'] = '\\n', ['\r'] = '\\r', ['\t'] = '\\t' }
local function esc(s)
  return (s:gsub('[%c"\\]', function(c) return ESC[c] or string.format("\\u%04x", c:byte()) end))
end
local function isArray(t)
  local n = 0
  for k in pairs(t) do
    if type(k) ~= "number" or k < 1 or k % 1 ~= 0 then return false end
    n = n + 1
  end
  for i = 1, n do if t[i] == nil then return false end end
  return true, n
end
function J.encode(v, indent, cur)
  indent = indent or ""
  cur = cur or ""
  local tv = type(v)
  if tv == "nil" then return "null"
  elseif tv == "boolean" then return v and "true" or "false"
  elseif tv == "number" then
    if v ~= v or v == math.huge or v == -math.huge then return "null" end
    if v % 1 == 0 and math.abs(v) < 1e15 then return string.format("%d", v) end
    return string.format("%.6g", v)
  elseif tv == "string" then return '"' .. esc(v) .. '"'
  elseif tv == "table" then
    local arr, n = isArray(v)
    local nl = (indent ~= "") and "\n" or ""
    local nxt = cur .. indent
    if arr then
      if n == 0 then return "[]" end
      local parts = {}
      for i = 1, n do parts[i] = nxt .. J.encode(v[i], indent, nxt) end
      return "[" .. nl .. table.concat(parts, "," .. nl) .. nl .. cur .. "]"
    end
    local keys = {}
    for k in pairs(v) do keys[#keys + 1] = k end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    local parts = {}
    for _, k in ipairs(keys) do
      parts[#parts + 1] = nxt .. '"' .. esc(tostring(k)) .. '":' .. ((indent ~= "") and " " or "") .. J.encode(v[k], indent, nxt)
    end
    return "{" .. nl .. table.concat(parts, "," .. nl) .. nl .. cur .. "}"
  end
  error("json: cannot encode " .. tv)
end
function J.decode(s)
  local i = 1
  local function ws() i = s:find("[^ \t\r\n]", i) or (#s + 1) end
  local val
  local function str()
    i = i + 1
    local buf = {}
    while true do
      local c = s:sub(i, i)
      if c == "" then error("json: unterminated string") end
      if c == '"' then i = i + 1; break end
      if c == "\\" then
        local e = s:sub(i + 1, i + 1)
        if e == "u" then
          local code = tonumber(s:sub(i + 2, i + 5), 16)
          if code < 0x80 then buf[#buf + 1] = string.char(code)
          elseif code < 0x800 then buf[#buf + 1] = string.char(0xC0 + math.floor(code / 64), 0x80 + code % 64)
          else buf[#buf + 1] = string.char(0xE0 + math.floor(code / 4096), 0x80 + math.floor(code / 64) % 64, 0x80 + code % 64) end
          i = i + 6
        else
          local map = { b = "\b", f = "\f", n = "\n", r = "\r", t = "\t" }
          buf[#buf + 1] = map[e] or e
          i = i + 2
        end
      else
        buf[#buf + 1] = c
        i = i + 1
      end
    end
    return table.concat(buf)
  end
  function val()
    ws()
    local c = s:sub(i, i)
    if c == "{" then
      i = i + 1
      local t = {}
      ws()
      if s:sub(i, i) == "}" then i = i + 1; return t end
      while true do
        ws()
        local k = str()
        ws()
        assert(s:sub(i, i) == ":", "json: expected ':'")
        i = i + 1
        t[k] = val()
        ws()
        local d = s:sub(i, i)
        i = i + 1
        if d == "}" then return t end
        assert(d == ",", "json: expected ',' or '}'")
      end
    elseif c == "[" then
      i = i + 1
      local t = {}
      ws()
      if s:sub(i, i) == "]" then i = i + 1; return t end
      while true do
        t[#t + 1] = val()
        ws()
        local d = s:sub(i, i)
        i = i + 1
        if d == "]" then return t end
        assert(d == ",", "json: expected ',' or ']'")
      end
    elseif c == '"' then return str()
    elseif s:sub(i, i + 3) == "true" then i = i + 4; return true
    elseif s:sub(i, i + 4) == "false" then i = i + 5; return false
    elseif s:sub(i, i + 3) == "null" then i = i + 4; return nil
    end
    local num = s:match("^-?%d+%.?%d*[eE]?[-+]?%d*", i)
    assert(num and #num > 0, "json: bad value at " .. i)
    i = i + #num
    return tonumber(num)
  end
  return val()
end
return J
