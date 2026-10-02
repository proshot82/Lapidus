import sys; sys.path.insert(0,'/home/user/Lapidus/build/l8j')
from mk import mk
P={'F':{'down':'N'},'S':{'left':'N'},'A':{'up':'N','right':'V'},'B':{'up':'V','down':'V'}}
W={'A':'elbow','B':'coupling'}
mk('e2',[
"###########",
"####F######",
"####.######",
"####B.....#",
"#...P.A.fH#",
"###.#.#####",
"###.#.S####",
"###~#######",
],P,what=W,washOk=True,note='e2: мыло под муфтой, выбить ногами влево в слив; угольник падает в столбец 6 на стояк')
