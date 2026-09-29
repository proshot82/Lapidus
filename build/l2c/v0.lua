-- Квартира 2 «Скалолаз». Авторский скелет, проверен солвером (build/cand/l2v4.lua, v4a).
local function wallup(tag)
  return function(d)
    local keep = {}
    for _, o in ipairs(d.objects) do
      if o.tag == tag then
        local r = d.grid[o.at[2]]
        d.grid[o.at[2]] = r:sub(1, o.at[1] - 1) .. "#" .. r:sub(o.at[1] + 1)
      else keep[#keep + 1] = o end
    end
    d.objects = keep
  end
end
-- Видимый проигрыш по мерке новичка: Лапидус целиком в колодце под шахтой (яма глубже его длины, без крючьев).
local WELL = { x1 = 3, x2 = 5, y1 = 6, y2 = 9 }
local function visibleLoss(lvl, st)
  for _, c in ipairs(st.body) do
    local x, y = (c - 1) % lvl.W + 1, math.floor((c - 1) / lvl.W) + 1
    if x < WELL.x1 or x > WELL.x2 or y < WELL.y1 or y > WELL.y2 then return false end
  end
  return true
end
return {
  visibleLoss = visibleLoss,
  id = 2, flat = 2, name = "Скалолаз",
  length = { 2, 4 }, pressure = 0, tile = "blue",
  target = { moves = { 15, 40 }, states = 50000, dead = 30, fb = 2 },
  grid = {
    "#########",
    "##......#",
    "#...#####",
    "#...##..#",
    "##......#",
    "##...####",
    "##...####",
    "##...####",
    "##...####",
    "#########",
  },
  objects = {
    { kind = "source", at = { 3, 2 }, ports = { right = "V" } },
    { kind = "fixture", what = "toilet", at = { 8, 2 }, ports = { left = "N" } },
    { kind = "stub", tag = "hook", at = { 2, 3 }, ports = { right = "V" } },
    { kind = "stub", tag = "hook", at = { 2, 4 }, ports = { right = "N" } },
    { kind = "lapidus", cells = { { 6, 5 }, { 7, 5 }, { 8, 5 } }, head = 3 },
  },
  ablations = { { name = "крючья замурованы", mutate = wallup("hook") }, { name = "резьба крючьев", flip = "hook" } },
  texts = {
    request = "Сижу на унитазе третью неделю. Жду воду. Не звоните в дверь.",
    hints = {
      "Отводы в шахте — скальные крючья: перехватывайтесь головой и ногами по очереди. Нижний крюк решает, каким концом начинать.",
      "Ваш звонок очень важен для нас. Проверяем, не висите ли вы зря.",
      "Мастер выехал. Держитесь за что-нибудь резьбовое.",
    },
  },
}
