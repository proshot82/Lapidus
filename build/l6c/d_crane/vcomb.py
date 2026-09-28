from O import O as O0
O = dict(O0)
O['F'] = '{ kind = "fixture", what = "heater", at = { {x}, {y} }, ports = { right = "V" } }'
O['R'] = '{ kind = "source", at = { {x}, {y} }, ports = { right = "N" } }'
O['n'] = '{ kind = "fitting", what = "nipple", tag = "B", at = { {x}, {y} }, ports = { left = "N", right = "N" } }'
O['k'] = '{ kind = "fitting", what = "coupling", tag = "C", at = { {x}, {y} }, ports = { left = "V", right = "V" } }'
def K(rows, cells=None, **kw):
    d = {'map': rows, 'vis': 'visC.lua'}; d.update(kw)
    if cells: d['cells'] = cells
    return d
# гребёнка: колонка и стояк на левой стене шахты (колонка выше), ниппель и муфта поднимаются по шахте,
# подключение — из «гребёнки» справа (два зуба и хребет).
V = {
 "g1": K(["#######",
          "#######",
          "#F...##",
          "##.#.##",
          "#R...##",
          "##n#.##",
          "##..###",
          "##k..##",
          "#######"], [(3,7),(4,7),(4,8),(3,9)][:0] or None),
}
