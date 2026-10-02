from O import O as O0
O = dict(O0)
O['H'] = '{ kind = "fixture", what = "heater", at = { {x}, {y} }, ports = { up = "V" } }'
O['U'] = '{ kind = "source", at = { {x}, {y} }, ports = { up = "N" } }'
O['c'] = '{ kind = "fitting", what = "coupling", tag = "C", at = { {x}, {y} }, ports = { up = "V", down = "V" } }'
O['b'] = '{ kind = "fitting", what = "nipple", tag = "B", at = { {x}, {y} }, ports = { up = "N", down = "N" } }'
def K(rows, cells, **kw):
    d = {'map': rows, 'vis': 'visP.lua', 'cells': cells}; d.update(kw); return d
base = ["##########",
        "###b#c####",
        "#........#",
        "###.#.####",
        "###.#.####",
        "###H#U####",
        "##########"]
V = {
 "dd1": K(base, [(2,3),(3,3),(4,3),(5,3),(6,3)]),
 "dd2": K(base, [(6,3),(5,3),(4,3),(3,3),(2,3)]),
 "dd3": K(base, [(4,3),(5,3),(6,3),(7,3),(8,3)]),
 "dd4": K(base, [(8,3),(7,3),(6,3),(5,3),(4,3)]),
 "dd5": K(base, [(3,3),(4,3),(5,3),(6,3),(7,3)]),
 "dd6": K(base, [(7,3),(6,3),(5,3),(4,3),(3,3)]),
}
