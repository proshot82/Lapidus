import sys; sys.path.insert(0,'/home/user/Lapidus/build/l8j')
from mk import mk
P={'F':{'down':'V'},'S':{'right':'N'},'A':{'left':'V','up':'V'},'B':{'up':'N','down':'N'}}
W={'A':'elbow','B':'nipple'}
mk('f1',[
"#########",
"####F####",
"####.####",
"####B...#",
"###.A.oH#",
"###.#.f.#",
"##S.#####",
"#########",
],P,what=W,note='f1: угольник — подставка под ниппелем; выбить его головой в жёлоб (прикипит к стояку), ниппель остаётся на голове')
