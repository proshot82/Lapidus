from O import O as O0
O = dict(O0)
O['D'] = '{ kind = "source", at = { {x}, {y} }, ports = { up = "N" } }'
O['c'] = '{ kind = "fitting", what = "elbow", tag = "C", at = { {x}, {y} }, ports = { left = "V", down = "V" } }'
O['b'] = '{ kind = "fitting", what = "nipple", tag = "B", at = { {x}, {y} }, ports = { up = "N", down = "N" } }'
def K(rows, cells, **kw):
    d = {'map': rows, 'vis': 'visP.lua', 'cells': cells}; d.update(kw); return d
base = ["#########",
        "###F#.###",
        "###.#.###",
        "###.#.###",
        "###b#c###",
        "###.....#",
        "###.#D#.#",
        "###.....#",
        "#########"]
V = {
 "kc1": K(base, [(4,8),(4,7),(4,6),(5,6),(6,6)]),
 "kc2": K(base, [(6,6),(5,6),(4,6),(4,7),(4,8)]),
 "kc3": K(base, [(8,6),(7,6),(6,6),(5,6),(4,6)]),
 "kc4": K(base, [(4,6),(5,6),(6,6),(7,6),(8,6)]),
 "kc5": K(base, [(5,8),(4,8),(4,7),(4,6),(5,6),(6,6)][1:]),
}
