import os, sys, subprocess
sys.path.insert(0, 'art')
import gen, screens2
body, extra = screens2.scenes6()
svg = '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="1920" height="1080" viewBox="0 0 1920 1080"><defs>%s%s</defs>%s</svg>' % (gen.DEFS, extra, body)
open('build/l6/prev/scene6.svg', 'w').write(svg)
subprocess.run(['rsvg-convert', '-o', 'build/l6/prev/scene6_full.png', 'build/l6/prev/scene6.svg'], check=True)
subprocess.run(['convert', 'build/l6/prev/scene6_full.png', '-crop', '588x648+56+156', '+repage', 'build/l6/prev/scene6.png'], check=True)
print('ok')
