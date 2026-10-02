import sys; sys.path.insert(0,'/home/user/Lapidus/build/l8j')
from mk import mk
P={'F':{'down':'V'},'S':{'right':'N'},'A':{'left':'V','up':'V'},'B':{'up':'N','down':'N'}}
W={'A':'elbow','B':'nipple'}
mk('h1',[
"##########",
"####F#####",
"####.#####",
"####B....#",
"###.A.oH.#",
"###.P.f..#",
"##S.######",
"###~######",
],P,what=W,washOk=True,note='h1: башенка мыло/угольник/ниппель; жёлоб слева: мыло в слив, угольник прикипает выше слива, ноги сверху в угольник')
