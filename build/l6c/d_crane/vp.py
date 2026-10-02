from O import O as O0
O = dict(O0)
O['W'] = '{ kind = "source", at = { {x}, {y} }, ports = { left = "N" } }'
O['c'] = '{ kind = "fitting", what = "elbow", tag = "C", at = { {x}, {y} }, ports = { right = "V", up = "V" } }'
O['b'] = '{ kind = "fitting", what = "nipple", tag = "B", at = { {x}, {y} }, ports = { up = "N", down = "N" } }'
def K(rows, cells, **kw):
    d = {'map': rows, 'vis': 'visP.lua', 'cells': cells}; d.update(kw); return d
base = ["##########",
        "##########",
        "###F######",
        "###.######",
        "###b#c####",
        "#........#",
        "#####.####",
        "#####.W###",
        "##########"]
V = {
 "p1": K(base, [(7,6),(6,6),(5,6),(4,6),(3,6)]),
 "p2": K(base, [(3,6),(4,6),(5,6),(6,6),(7,6)]),
 "p3": K(base, [(8,6),(7,6),(6,6),(5,6),(4,6)]),
 "p4": K(base, [(4,6),(5,6),(6,6),(7,6),(8,6)]),
 "p5": K(base, [(2,6),(3,6),(4,6),(5,6),(6,6)]),
 "p6": K(base, [(6,6),(5,6),(4,6),(3,6),(2,6)]),
}
