import sys; sys.path.insert(0,'/home/user/Lapidus/build/l8j')
from mk import mk
P={'F':{'down':'V'},'S':{'right':'N'},'A':{'left':'V','right':'V'},'B':{'up':'N','down':'N'}}
W={'A':'coupling','B':'nipple'}
mk('g1',[
"##########",
"####F#####",
"####.#####",
"####B....#",
"###.A.oH.#",
"##S.P.f..#",
"###.######",
"###~######",
],P,what=W,washOk=True,note='g1: башня мыло/муфта/ниппель в нише; мыло — ногами в жёлоб, муфту — головой (прикипает на лету), ниппель на голове')
