-- build/l6/pick.lua список.lua "тег" [rank] — сохранить лучший старт раскладки как def (печатает путь к файлу)
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local U = dofile("build/l6/union.lua")
local list = dofile(arg[1])
local tag, rank = arg[2], tonumber(arg[3] or "1")
for _, def in ipairs(list) do
  if def.tagname == tag then
    local lvl = R.compile(def)
    -- повторяем startsFor из sweep
    local SW = {}
    local occ, cq = {}, nil
    for q, p in ipairs(lvl.pieces) do if p.tag == def.carry then cq = q else occ[p.start] = true end end
    local starts, meta, seenK = {}, {}, {}
    local function empty(c) return c ~= 0 and lvl.cell[c] == R.EMPTY and not occ[c] end
    local function try(body)
      for bi = 1, #body do
        local up = lvl.nb[body[bi]][R.UP]
        local onBody = false
        for _, c in ipairs(body) do if c == up then onBody = true end end
        if up ~= 0 and empty(up) and not onBody then
          local st = { body = {}, pos = {}, asm = {}, fixed = {}, dead = false }
          for i = 1, #body do st.body[i] = body[i] end
          for q, p in ipairs(lvl.pieces) do st.pos[q] = p.start; st.asm[q] = q; st.fixed[q] = not p.movable end
          st.pos[cq] = up
          local k0 = R.key(st)
          if R.settle(lvl, st) and not st.dead and R.key(st) == k0 and not R.isWin(lvl, st) and not seenK[k0] then
            seenK[k0] = true
            local bb = {}; for i = 1, #body do bb[i] = body[i] end
            starts[#starts + 1] = st; meta[#meta + 1] = { body = bb, nip = up }
          end
        end
      end
    end
    local function ext(body, used, L)
      if #body == L then try(body); return end
      local c = body[#body]
      for d = 1, 4 do
        local t = lvl.nb[c][d]
        if empty(t) and not used[t] then used[t] = true; body[#body + 1] = t; ext(body, used, L); body[#body] = nil; used[t] = nil end
      end
    end
    local L1, L2 = (def.startLen or def.length)[1], (def.startLen or def.length)[2]
    for L = L1, L2 do for c = 1, lvl.N do if empty(c) then ext({ c }, { [c] = true }, L) end end end
    local G = U.build(lvl, starts, 1500000)
    local rows = {}
    for i = 1, #starts do
      local m = U.metrics(G, G.sid[i], false)
      if m and m.wins == 1 and m.maxw <= 3 then rows[#rows + 1] = { i = i, m = m } end
    end
    for _, r in ipairs(rows) do r.key = r.m.opt - math.max(0, r.m.walk - 6) * 4 end
    table.sort(rows, function(a, b) if a.key ~= b.key then return a.key > b.key end return a.m.fb > b.m.fb end)
    local r = rows[rank]
    io.stderr:write(string.format('rows=%d opt=%d walk=%d key=%s\n', #rows, r.m.opt, r.m.walk, tostring(r.key)))
    local mt = meta[r.i]
    local cells = {}
    for k, c in ipairs(mt.body) do local x, y = R.xy(lvl, c); cells[k] = { x, y } end
    local nx, ny = R.xy(lvl, mt.nip)
    local L = { "return {", string.format("  id = 6, flat = 6, name = %q, length = { %d, %d }, pressure = 0,", "Намертво", def.length[1], def.length[2]), "  grid = {" }
    for _, row in ipairs(def.grid) do L[#L + 1] = string.format("    %q,", row) end
    L[#L + 1] = "  },"
    L[#L + 1] = "  objects = {"
    for _, o in ipairs(def.objects) do
      if o.kind ~= "lapidus" then
        local at = o.at
        if o.tag == def.carry then at = { nx, ny } end
        local ps = {}
        for _, s in ipairs({ "up", "right", "down", "left" }) do if o.ports and o.ports[s] then ps[#ps + 1] = s .. " = \"" .. o.ports[s] .. "\"" end end
        L[#L + 1] = string.format("    { kind = %q,%s%s at = { %d, %d }, ports = { %s } },", o.kind, o.what and string.format(" what = %q,", o.what) or "", o.tag and string.format(" tag = %q,", o.tag) or "", at[1], at[2], table.concat(ps, ", "))
      end
    end
    local cs = {}
    for _, c in ipairs(cells) do cs[#cs + 1] = string.format("{ %d, %d }", c[1], c[2]) end
    L[#L + 1] = string.format("    { kind = \"lapidus\", cells = { %s }, head = %d },", table.concat(cs, ", "), #cells)
    L[#L + 1] = "  },"
    L[#L + 1] = "  ablations = { { name = \"без ниппеля\", remove = \"nip\" } },"
    L[#L + 1] = "}"
    local out = arg[4] or "build/l6/pick_out.lua"
    local f = io.open(out, "w"); f:write(table.concat(L, "\n") .. "\n"); f:close()
    print(out)
  end
end
