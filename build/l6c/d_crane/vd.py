from O import O as O0
O = dict(O0)
O['S'] = '{ kind = "source", at = { {x}, {y} }, ports = { down = "N" } }'
O['c'] = '{ kind = "fitting", what = "coupling", tag = "C", at = { {x}, {y} }, ports = { up = "V", down = "V" } }'
O['b'] = '{ kind = "fitting", what = "nipple", tag = "B", at = { {x}, {y} }, ports = { up = "N", down = "N" } }'
def K(rows, cells=None, **kw):
    d = {'map': rows, 'vis': 'vis0.lua'}; d.update(kw)
    if cells: d['cells'] = cells
    return d
# две «двери» в потолке: стояк над Q, колонка над Z; муфту поднимают в Q снизу, ниппель вдвигают в Z сбоку
V = {
 "d1": K(["#########",
          "##S#F####",
          "#.....b.#",
          "##c#.####",
          "##hoof..#",
          "#########"]),
 "d2": K(["#########",
          "##S#F####",
          "#.....b.#",
          "##c#.##.#",
          "##hoof..#",
          "#########"]),
}
