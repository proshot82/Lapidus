#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""tools/review_page.py — страница визуального согласования из build/review/*.png (JPEG внутри HTML)."""
import base64, os, subprocess, html
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
import sys
SRC = os.path.join(ROOT, 'build', sys.argv[1] if len(sys.argv) > 1 else 'review')
OUT = '/mnt/user-data/outputs/lapidus_review.html'

def img(name):
    jpg = '/tmp/review_%s.jpg' % name
    subprocess.run(['convert', os.path.join(SRC, name + '.png'), '-quality', '85', jpg], check=True)
    return base64.b64encode(open(jpg, 'rb').read()).decode()

SECTIONS = [
    ('Элементы', [('01_gallery', 'Стены — плитка своей квартиры (мятная, голубая, горчичная), фон — зелёная панель на 2/3 и побелка. Н — торчащий штуцер с витками, В — утопленное шестигранное гнездо: различаются формой, не только цветом. Закреплённое темнее и держится на хомуте; яркая латунь — подвижные детали для квартир 4–10. Внизу — состояния героя.')]),
    ('Квартиры 1–3 · стартовые позиции', [
        ('02_level1', 'Кв. 1 «Не той стороной», поле 10×7. Слева — табличка квартиры, счётчик ходов и активный конец; справа — кнопки ↶ ⟲ ? ≡ (они же для тача).'),
        ('03_level2', 'Кв. 2 «Скалолаз», поле 9×10: шахта с крючьями у левой стены, под уступом — яма.'),
        ('04_level3', 'Кв. 3 «Мыло», поле 11×8: фаянсовые бачки, мойка на полке. Внизу — пример отказа хода.')]),
    ('Экраны', [
        ('05_menu', 'Меню — подвал у главного вентиля дома; Лапидус выглядывает из-за стояка. Логотип — буквы из латунных труб, по которым бежит вода.'),
        ('06_select', 'Выбор квартиры — хрущёвка в разрезе: решённая горит, вода в стояке поднимается; открыты две нерешённые; 4–10 — в следующей версии.'),
        ('07_request', 'Заявка жильца перед квартирой — рукописный шрифт Neucha.'),
        ('08_hint', 'Горячая линия управляющей компании: три ступени подсказки.'),
        ('09_act', 'Победа — «Акт выполненных работ» со штампом, разрядом и отметками о звонках и мастере.'),
        ('10_passport', '«Паспорт изделия» — правила в пиктограммах перед первой квартирой.'),
        ('11_washed', 'Если Лапидуса смыло.'),
        ('12_scenes', 'Немые сцены после победы — ключевые кадры; в игре они анимированы.')]),
]

CSS = """
:root{--bg:#f3efe6;--fg:#1f2328;--muted:#5a636d;--card:#ffffff;--line:#d8d1c3;--accent:#a8791f;
box-sizing:border-box;padding-top:env(safe-area-inset-top,0px);padding-bottom:env(safe-area-inset-bottom,0px)}
@media (prefers-color-scheme: dark){:root:not([data-theme="light"]){--bg:#14171a;--fg:#ece6da;--muted:#a2acb5;--card:#1d2226;--line:#30373d;--accent:#d7ab4a}}
:root[data-theme="dark"]{--bg:#14171a;--fg:#ece6da;--muted:#a2acb5;--card:#1d2226;--line:#30373d;--accent:#d7ab4a}
html{scroll-padding-top:env(safe-area-inset-top,0px)}
*,*::before,*::after{box-sizing:inherit}
body{margin:0;background:var(--bg);color:var(--fg);font:16px/1.55 system-ui,-apple-system,"Segoe UI",Roboto,"Noto Sans",sans-serif}
main{max-width:1120px;margin:0 auto;padding:22px 16px 56px}
h1{font-size:1.55rem;line-height:1.25;margin:.2em 0 .4em}
h2{font-size:1.2rem;margin:1.8em 0 .7em;padding-bottom:.25em;border-bottom:2px solid var(--accent)}
p.lead{color:var(--muted);margin:0 0 1em}
ul.notes{color:var(--muted);margin:.2em 0 1.2em;padding-left:1.2em}
figure{margin:0 0 20px;background:var(--card);border:1px solid var(--line);border-radius:12px;overflow:hidden}
figure img{display:block;width:100%;height:auto;max-width:100%}
figcaption{padding:10px 14px;color:var(--muted);font-size:.95rem}
"""

parts = ['<!doctype html><html lang="ru"><head><meta charset="utf-8">',
         '<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">',
         '<title>Лапидус. Ни капли — визуальное согласование</title><style>%s</style></head><body><main>' % CSS,
         '<h1>«Лапидус. Ни капли» — визуальное согласование, квартиры 1–3</h1>',
         '<p class="lead">Второй проход в утверждённом стиле: скруглённая кладка с плиточной облицовкой, светотень от одного источника, контур «от руки»; герой — канонический Лапидус (лысеющий усатый брюнет с мыльной пеной на макушке). Всё нарисовано кодом: SVG → PNG, палитра §8, шрифты PT Sans Narrow и Neucha (OFL, кириллица). Решений уровней здесь нет — только стартовые позиции и примеры состояний.</p>',
         '<ul class="notes"><li>В игре анимировано: пол-оборота при свинчивании с пухом уплотнительной ленты, squash and stretch на каждом шаге, бегущая по мокрым трубам вода, пульс активного конца, гримасы приборов, загорание квартир.</li><li>Звук и музыка (§9) в макетах не показаны.</li></ul>']
for title, items in SECTIONS:
    parts.append('<h2>%s</h2>' % html.escape(title))
    for name, cap in items:
        parts.append('<figure><img alt="%s" src="data:image/jpeg;base64,%s"><figcaption>%s</figcaption></figure>' % (html.escape(cap), img(name), html.escape(cap)))
parts.append('</main></body></html>')
open(OUT, 'w', encoding='utf-8').write(''.join(parts))
print(OUT, os.path.getsize(OUT))
