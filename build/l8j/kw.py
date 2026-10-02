import sys, subprocess; sys.path.insert(0,'/home/user/Lapidus/build/l8j')
from mk import mk
P={'F':{'down':'V'},'S':{'down':'N'},'B':{'up':'N','down':'V'},'A':{'left':'V'}}
W={'B':'adapter','A':'plug'}
rows=["#############",
      "##########F##",
      "########S#.##",
      "#H..B......##",
      "#of.A......##",
      "#####.###..##",
      "#####~###~~##"]
mk('kw1',rows,P,what=W,washOk=True,mustLift=['B'],note='kw1: kv_9_11_10 с латунной подставкой (заглушка) вместо мыла: выбивать можно любым концом')
