import sys; sys.path.insert(0,'/home/user/Lapidus/build/l8j')
from mk import mk
P={'F':{'down':'V'},'S':{'right':'N'},'A':{'left':'V','right':'V'},'B':{'up':'N','down':'N'}}
W={'A':'coupling','B':'nipple'}
mk('g2',[
"############",
"####F#######",
"####.#.....#",
"####B......#",
"###.A......#",
"##S.P......#",
"###.###.oH.#",
"###~####f..#",
"############",
],P,what=W,washOk=True,note='g2: затравка мутатора — ядро g1 слева, свободная правая комната')
