import sys; sys.path.insert(0,'/home/user/Lapidus/build/l8j')
from mk import mk
P={'F':{'down':'N'},'S':{'down':'N'},'B':{'up':'V','down':'V'}}
W={'B':'coupling'}
mk('k5',[
"#############",
"#############",
"#########SF##",
"#H..B......##",
"#of.P......##",
"#####.###..##",
"#####.#######",
"#####~#######",
],P,what=W,washOk=True,mustLift=['B'],note='k5: конвейер; яма (10..11,6) под стояком и мойкой')
