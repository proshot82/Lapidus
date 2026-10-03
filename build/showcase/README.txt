Лист элементов игры в реальном масштабе (витрины — не уровни). Пересобрать:
  cp build/showcase/9[12].lua levels/ && LAP_LEVELS=91,92 python3 art/export_lvl.py 91 92
  LAP_LEVELS=91,92 ALSOFT_DRIVERS=null xvfb-run -a -s "-screen 0 1920x1080x24" love . --unlock --level 1 --shot out1.png   (2 — латунь)
  затем удалить levels/91.lua, levels/92.lua, assets/gfx/lvl91.jpg, lvl92.jpg
