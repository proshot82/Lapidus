-- mk.lua — сборка кандидата направления E из компактного описания (для ручной доводки).
-- local mk = dofile("build/l6c/e_orientation/mk.lua"); return mk{ grid = {...}, src = {x,y,"left","N"}, fx = {x,y,"down","V"},
--   pieces = { {tag, what, x, y, {ports}} ... }, lap = {{x,y},...}, head = 1|n, len = {3,5}, vis = function|nil, abl = {...} }
return function(o)
  local objs = {}
  objs[#objs + 1] = { kind = "source", at = { o.src[1], o.src[2] }, ports = { [o.src[3]] = o.src[4] } }
  objs[#objs + 1] = { kind = "fixture", what = "heater", at = { o.fx[1], o.fx[2] }, ports = { [o.fx[3]] = o.fx[4] } }
  for _, s in ipairs(o.stubs or {}) do objs[#objs + 1] = { kind = "stub", tag = s.tag, at = { s[1], s[2] }, ports = { [s[3]] = s[4] } } end
  for _, p in ipairs(o.pieces) do
    objs[#objs + 1] = { kind = "fitting", tag = p[1], what = p[2], at = { p[3], p[4] }, ports = p[5] }
  end
  objs[#objs + 1] = { kind = "lapidus", cells = o.lap, head = o.head or #o.lap }
  return {
    id = 6, flat = 6, name = "Намертво", length = o.len or { 3, 5 }, pressure = 0, tile = "mustard",
    grid = o.grid, objects = objs, visibleLoss = o.vis, ablations = o.abl, note = o.note, texts = o.texts,
  }
end
