import sys; sys.path.insert(0,'/home/user/Lapidus/build/l8j')
from mk import mk
P={'F':{'down':'V'},'S':{'right':'N'},'A':{'left':'V','right':'V'},'B':{'up':'N','down':'N'}}
W={'A':'coupling','B':'nipple'}
mk('h2',[
"##########",
"####F#####",
"####.#.fo#",
"####B...H#",
"###.A.####",
"##S.P.####",
"###.######",
"###~######",
],P,what=W,washOk=True,note='h2: ядро g1 + колодец (6,4..6): в колодец входить ногами вперёд')
