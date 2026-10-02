import sys; sys.path.insert(0,'/home/user/Lapidus/build/l8j')
from mk import mk
P={'F':{'down':'V'},'S':{'down':'N'},'B':{'up':'N','down':'V'}}
W={'B':'adapter'}
mk('k2',[
"############",
"#########F##",
"#######S#.##",
"#H..B......#",
"#of.P......#",
"#####.######",
"#####~######",
],P,what=W,washOk=True,mustLift=['B'],note='k2: конвейер: переходник на мыле; мыло ногами в слив, переходник везти на спине, ногами поднять, голова в стояк')
