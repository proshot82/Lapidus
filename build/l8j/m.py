import sys; sys.path.insert(0,'/home/user/Lapidus/build/l8j')
from mk import mk
P={'F':{'down':'N'},'S':{'down':'N'},'B':{'up':'V','down':'N'},'C':{'up':'V','down':'V'}}
W={'B':'adapter','C':'coupling'}
mk('m1',[
"#############",
"#############",
"#######S#F###",
"#H.C.B......#",
"#of#P#......#",
"######....###",
"#############",
],P,what=W,washOk=True,mustLift=['B','C'],note='m1: два груза на спине; муфта — под стояк первой, иначе переходник прикипит к стояку')
