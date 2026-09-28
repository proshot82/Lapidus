from O import O as O0
O = dict(O0)
O['F'] = '{ kind = "fixture", what = "heater", at = { {x}, {y} }, ports = { right = "V" } }'
O['R'] = '{ kind = "source", at = { {x}, {y} }, ports = { right = "N" } }'
O['n'] = '{ kind = "fitting", what = "nipple", tag = "B", at = { {x}, {y} }, ports = { left = "N", right = "N" } }'
O['k'] = '{ kind = "fitting", what = "coupling", tag = "C", at = { {x}, {y} }, ports = { left = "V", right = "V" } }'
def K(rows, cells, **kw):
    d = {'map': rows, 'vis': 'vis0.lua', 'cells': cells}; d.update(kw); return d
V = {
 "c1": K(["#######",
          "#F...##",
          "#R...##",
          "##n#.##",
          "##..###",
          "##k.###",
          "##..###",
          "#######"], [(3,5),(4,5),(4,6),(4,7),(3,7)]),
 "c2": K(["#######",
          "#F...##",
          "#R...##",
          "##n#.##",
          "##...##",
          "##k..##",
          "##...##",
          "#######"], [(3,5),(4,5),(4,6),(4,7),(3,7)]),
}
