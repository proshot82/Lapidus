import sys, subprocess
sys.path.insert(0, 'art')
import gen, screens2
body, extra = screens2.card6()
svg = '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="564" height="380" viewBox="0 0 564 380"><defs>%s%s</defs>%s</svg>' % (gen.DEFS, extra, body)
open('build/l6/prev/card6.svg', 'w').write(svg)
subprocess.run(['rsvg-convert', '-o', 'build/l6/prev/card6.png', 'build/l6/prev/card6.svg'], check=True)
print('ok')
