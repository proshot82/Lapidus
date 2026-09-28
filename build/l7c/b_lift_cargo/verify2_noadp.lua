-- verify2_noadp.lua — p2b без переходника (для оценки его роли; разметка — авторская из p2b.lua). Только для проверки.
local d = dofile("build/l7c/b_lift_cargo/p2b.lua")
local keep = {}
for _, o in ipairs(d.objects) do if o.tag ~= "adp" then keep[#keep + 1] = o end end
d.objects = keep
d.stack = { "plug", "tee" }
d.ablations = {
  { name = "без заглушки", remove = "plug" },
  { name = "без ниппеля", remove = "nip" },
  { name = "струя не поднимает детали", filter = d.ablations[3].filter },
  { name = "заглушка не едет раньше тройника", filter = d.ablations[4].filter },
}
return d
