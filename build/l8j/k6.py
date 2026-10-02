import sys; sys.path.insert(0,'/home/user/Lapidus/build/l8j')
from mk import mk
P={'F':{'down':'V'},'S':{'down':'N'},'B':{'up':'N','down':'V'}}
W={'B':'adapter'}
mk('k6',[
"#############",
"#############",
"#########SF##",
"#H..B......##",
"#of.P......##",
"#####.###..##",
"#####~###~~##",
],P,what=W,washOk=True,mustLift=['B'],note='k6: конвейер; у мойки — слив во всю глубину: поднять переходник можно только повиснув головой на стояке')
