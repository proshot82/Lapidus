from O import O as O0
O = dict(O0)
O['U'] = '{ kind = "source", at = { {x}, {y} }, ports = { up = "N" } }'
O['c'] = '{ kind = "fitting", what = "coupling", tag = "C", at = { {x}, {y} }, ports = { up = "V", down = "V" } }'
O['b'] = '{ kind = "fitting", what = "nipple", tag = "B", at = { {x}, {y} }, ports = { up = "N", down = "N" } }'
def K(rows, cells=None, **kw):
    d = {'map': rows, 'vis': 'visK.lua'}; d.update(kw)
    if cells: d['cells'] = cells
    return d
# K2: ниппель над развилкой J, голова под ним; сдвиг головой в боковой ход переносит ниппель на ноги;
# муфта лежит в боковом ходе дальше, её сталкивают в колонну сверху, она падает на стояк внизу колонны.
V = {
 "K2a": K(["##########",
           "###F######",
           "###.######",
           "###.######",
           "###b######",
           "###....c.#",
           "###.####.#",
           "###.....##",
           "###U######"], [(6,8),(5,8),(4,8),(4,7),(4,6)], length=(3,5)),
}
