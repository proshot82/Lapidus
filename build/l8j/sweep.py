import sys, subprocess, itertools; sys.path.insert(0,'/home/user/Lapidus/build/l8j')
from mk import mk
P={'F':{'down':'N'},'S':{'down':'N'},'B':{'up':'V','down':'V'}}
W={'B':'coupling'}
def run(name):
    out=subprocess.run(['luajit','build/l6b/check.lua','build/l8j/%s.lua'%name],cwd='/home/user/Lapidus',capture_output=True,text=True).stdout.split('\n')
    return ' '.join(out[:3])
import re
def short(s):
    m=re.search(r'ходов (\d+).*СКРЫТЫХ (\d+) %.*ОБЕЗЬЯНА ([\d.]+).*ГЛУБИНА (\d+).*кратчайших (\d+), ширина (\d+)', s)
    return m.groups() if m else s[:60]
cands=[]
for L in [(2,5),(3,5),(4,5)]:
  for dip0 in [6,7]:
    for drainx in [3,4,5,6]:
      row6=['#']*13
      for x in range(dip0,12): row6[x-1]='.'
      row6[drainx-1]='.'
      row7=['#']*13; row7[drainx-1]='.'
      row8=['#']*13; row8[drainx-1]='~'
      rows=["#############","##########F##","########S#.##","#H..B......##","#of.P......##",''.join(row6),''.join(row7),''.join(row8)]
      if drainx in (3,): rows[4]="#of.P......##"
      name='sw'
      try:
        mk(name,rows,P,what=W,washOk=True,mustLift=['B'],note='sweep',L=L)
      except Exception as e:
        print('err',e); continue
      print(L,dip0,drainx,short(run(name)))
