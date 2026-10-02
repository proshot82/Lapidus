import sys; sys.path.insert(0,'/home/user/Lapidus/build/l8j')
from mk import mk
P={'F':{'down':'N'},'S':{'down':'N'},'B':{'up':'V','down':'V'}}
W={'B':'coupling','F':'heater'}
def go(name, rows, note, L=(2,5)):
    mk(name, rows, P, what=W, washOk=True, mustLift=['B'], note=note, L=L)
go('q1',["##########",
         "#######F##",
         "######S.##",
         "##.B....##",
         "#HfP....##",
         "####....##",
         "####.#####",
         "####~#####"],'q1: муфта сразу у ныряния; мыло — в слив, стояк 7, колонка 8')
