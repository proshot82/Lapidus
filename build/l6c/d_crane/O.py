# общие объекты для прототипов направления D
O = {
 'F': '{ kind = "fixture", what = "heater", at = { {x}, {y} }, ports = { down = "V" } }',
 'S': '{ kind = "source", at = { {x}, {y} }, ports = { down = "N" } }',
 'R': '{ kind = "source", at = { {x}, {y} }, ports = { right = "N" } }',
 'L': '{ kind = "source", at = { {x}, {y} }, ports = { left = "N" } }',
 'c': '{ kind = "fitting", what = "coupling", tag = "C", at = { {x}, {y} }, ports = { up = "V", down = "V" } }',
 'k': '{ kind = "fitting", what = "coupling", tag = "C", at = { {x}, {y} }, ports = { left = "V", right = "V" } }',
 'b': '{ kind = "fitting", what = "nipple", tag = "B", at = { {x}, {y} }, ports = { up = "N", down = "N" } }',
}
O['U'] = '{ kind = "source", at = { {x}, {y} }, ports = { up = "N" } }'
O['e'] = '{ kind = "fitting", what = "elbow", tag = "C", at = { {x}, {y} }, ports = { down = "V", right = "V" } }'
O['E'] = '{ kind = "fitting", what = "elbow", tag = "C", at = { {x}, {y} }, ports = { down = "V", left = "V" } }'
O['g'] = '{ kind = "fitting", what = "elbow", tag = "C", at = { {x}, {y} }, ports = { left = "V", up = "V" } }'
O['G'] = '{ kind = "fitting", what = "elbow", tag = "C", at = { {x}, {y} }, ports = { right = "V", up = "V" } }'
O['D'] = '{ kind = "source", at = { {x}, {y} }, ports = { up = "V" } }'
O['Q'] = '{ kind = "source", at = { {x}, {y} }, ports = { left = "V" } }'
O['P'] = '{ kind = "source", at = { {x}, {y} }, ports = { right = "V" } }'
O['a'] = '{ kind = "fitting", what = "elbow", tag = "C", at = { {x}, {y} }, ports = { right = "V", up = "V" } }'
O['W'] = '{ kind = "source", at = { {x}, {y} }, ports = { left = "N" } }'
O['j'] = '{ kind = "fitting", what = "elbow", tag = "C", at = { {x}, {y} }, ports = { left = "V", down = "V" } }'
O['J'] = '{ kind = "fitting", what = "elbow", tag = "C", at = { {x}, {y} }, ports = { right = "V", down = "V" } }'
O['l'] = '{ kind = "fitting", what = "elbow", tag = "C", at = { {x}, {y} }, ports = { down = "V", left = "V" } }'
