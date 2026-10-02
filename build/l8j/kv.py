import sys, subprocess; sys.path.insert(0,'/home/user/Lapidus/build/l8j')
from mk import mk
P={'F':{'down':'V'},'S':{'down':'N'},'B':{'up':'N','down':'V'}}
W={'B':'adapter'}
for xS in (7,8,9):
  for D in (xS+1, xS+2):
    if D>11: continue
    for d0 in range(xS-1, D+1):
      row3=['#']*13; row3[xS-1]='S'; row3[D-1]='.'
      row2=['#']*13; row2[D-1]='F'
      row6=list("#####.#######")
      row7=list("#####~#######")
      for x in range(d0, D+1): row6[x-1]='.'; row7[x-1]='~'
      rows=["#############",''.join(row2),''.join(row3),"#H..B......##","#of.P......##",''.join(row6),''.join(row7)]
      name='kv_%d_%d_%d'%(xS,D,d0)
      mk(name,rows,P,what=W,washOk=True,mustLift=['B'],note='перебор финиша над сливом')
      out=subprocess.run(['luajit','build/l6b/check.lua','build/l8j/%s.lua'%name],cwd='/home/user/Lapidus',capture_output=True,text=True).stdout.split('\n')
      print(name, out[0][:100], '|', out[1][:70] if len(out)>1 else '')
