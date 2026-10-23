# art/blender/fixtures.py — приборы (ванна, унитаз, раковина, стиральная машина, полотенцесушитель, газовая колонка):
# 3D-форма по настоящим пропорциям, рендер в 2D-мультяшном виде, как латунь (art/blender/fittings.py): ступенчатая
# заливка, тёмная обводка Freestyle, ортокамера спереди и чуть сверху (видно край ванны и бачка), прозрачный фон.
# Лица, пар, струя, пламя и иней — отдельным слоем поверх (art/fx_compose.py): точки привязки пишутся в anchors.json.
# Запуск: blender -b -P art/blender/fixtures.py -- <выходная папка> [bath toilet ...]
# Единица длины = клетка поля; холст 480×480 = 2 клетки; вход прибора — слева (движок отражает спрайт при входе справа).
import bpy, bmesh, math, sys, os, json
from mathutils import Vector, Matrix
from bpy_extras.object_utils import world_to_camera_view

argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
OUT = argv[0] if argv else '/tmp/fx3d'
ONLY = set(argv[1:])
os.makedirs(OUT, exist_ok=True)
TILT = math.radians(14)  # камера чуть сверху
RES = int(os.environ.get('FX_RES', '480'))  # 960 — крупные приборы для немых сцен


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.render.engine = 'BLENDER_EEVEE'
    sc.render.resolution_x = sc.render.resolution_y = RES
    sc.render.film_transparent = True
    sc.view_settings.view_transform = 'Standard'
    sc.render.use_freestyle = True
    sc.render.line_thickness_mode = 'ABSOLUTE'
    vl = sc.view_layers[0]
    ls = vl.freestyle_settings.linesets.new('ol')
    ls.select_by_visibility = True
    ls.select_by_edge_types = True
    ls.select_silhouette = True
    ls.select_border = True
    ls.select_crease = False
    ls.select_external_contour = True
    if ls.linestyle is None:
        ls.linestyle = bpy.data.linestyles.new('ol')
    ls.linestyle.color = (0.043, 0.027, 0.016)
    ls.linestyle.thickness = 4.5 * RES / 480
    for other in vl.freestyle_settings.linesets:
        if other.linestyle is None:
            other.linestyle = ls.linestyle
    cam = bpy.data.objects.new('cam', bpy.data.cameras.new('cam'))
    cam.data.type = 'ORTHO'
    cam.data.ortho_scale = 2.0
    cam.location = (0, -10 * math.cos(TILT), 10 * math.sin(TILT))
    cam.rotation_euler = (math.radians(90) - TILT, 0, 0)
    sc.collection.objects.link(cam)
    sc.camera = cam
    sun = bpy.data.objects.new('sun', bpy.data.lights.new('sun', 'SUN'))
    sun.data.energy = 3.0
    sun.rotation_euler = (math.radians(50), math.radians(-35), math.radians(-25))  # свет сверху-слева, как во всём арте
    sc.collection.objects.link(sun)
    sc.world = bpy.data.worlds.new('w')
    sc.world.use_nodes = True
    sc.world.node_tree.nodes['Background'].inputs[1].default_value = 0.0


def lin(c):  # sRGB hex → линейный
    c = c.lstrip('#'); v = [int(c[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    return tuple(x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in v)


def toon(name, dark, mid, light, spec):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    nt.nodes.clear()
    out = nt.nodes.new('ShaderNodeOutputMaterial')
    dif = nt.nodes.new('ShaderNodeBsdfDiffuse')
    s2r = nt.nodes.new('ShaderNodeShaderToRGB')
    ramp = nt.nodes.new('ShaderNodeValToRGB')
    emi = nt.nodes.new('ShaderNodeEmission')
    cr = ramp.color_ramp
    cr.interpolation = 'CONSTANT'
    cr.elements[0].position, cr.elements[0].color = 0.0, (*lin(dark), 1)
    cr.elements[1].position, cr.elements[1].color = 0.18, (*lin(mid), 1)
    e = cr.elements.new(0.55); e.color = (*lin(light), 1)
    e = cr.elements.new(0.92); e.color = (*lin(spec), 1)
    nt.links.new(dif.outputs[0], s2r.inputs[0])
    nt.links.new(s2r.outputs[0], ramp.inputs[0])
    nt.links.new(ramp.outputs[0], emi.inputs[0])
    nt.links.new(emi.outputs[0], out.inputs[0])
    return m


def flat(name, col):
    """Плоский цвет без света (стекло иллюминатора, вода в ванне, тёмная глубина)."""
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    nt.nodes.clear()
    out = nt.nodes.new('ShaderNodeOutputMaterial')
    emi = nt.nodes.new('ShaderNodeEmission')
    emi.inputs[0].default_value = (*lin(col), 1)
    nt.links.new(emi.outputs[0], out.inputs[0])
    return m


M = {}


def mats():
    M['enamel'] = toon('enamel', '#9FAAB6', '#DDE3EA', '#F4F7FA', '#FFFFFF')
    M['cream'] = toon('cream', '#A89C82', '#E6DCC4', '#F3EBD8', '#FFFBF0')
    M['chrome'] = toon('chrome', '#5E6770', '#A3ADB7', '#D3DAE1', '#FFFFFF')
    M['alu'] = toon('alu', '#6F7780', '#AEB6BE', '#CDD3D9', '#EEF2F5')
    M['brass'] = toon('brass', '#7A5414', '#C9962E', '#EBC260', '#FFF3C2')
    M['seat'] = toon('seat', '#1C1A18', '#2E2B28', '#45413C', '#6B6660')
    M['panel'] = toon('panel', '#8C96A1', '#C3CBD3', '#D9DFE5', '#F2F5F7')
    M['knob'] = toon('knob', '#1A1D20', '#2E3338', '#454B52', '#6B737B')
    M['towel'] = toon('towel', '#2F6E8C', '#4F9BC0', '#78BBDA', '#B5DDF0')
    M['inner'] = flat('inner', '#C5CFDA')
    M['water'] = flat('water', '#5EC4EA')
    M['glass'] = flat('glass', '#2E3A44')
    M['glassw'] = flat('glassw', '#8FD4F0')
    M['hole'] = flat('hole', '#16222C')


def finish(o, mat, smooth=True):
    if smooth:
        bpy.ops.object.shade_smooth()
    o.data.materials.append(M[mat])
    return o


def rbox(x0, x1, z0, z1, y0, y1, bev, mat, seg=5):
    """Скруглённый брусок по границам (x — ширина, z — высота, y — глубина; y<0 — к зрителю)."""
    bpy.ops.mesh.primitive_cube_add(size=1, location=((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2))
    o = bpy.context.object
    o.scale = (x1 - x0, y1 - y0, z1 - z0)
    bpy.ops.object.transform_apply(scale=True)
    if bev > 0:
        md = o.modifiers.new('b', 'BEVEL'); md.width = bev; md.segments = seg; md.limit_method = 'NONE'
        bpy.ops.object.modifier_apply(modifier='b')
    return finish(o, mat)


def prism(pts, y0, y1, mat, bev=0.02):
    """Тело по контуру вида спереди pts [(x, z)], вытянутое по глубине y0..y1, рёбра скруглены."""
    bm = bmesh.new()
    vs = [bm.verts.new((x, y0, z)) for x, z in pts]
    f = bm.faces.new(vs)
    r = bmesh.ops.extrude_face_region(bm, geom=[f])
    for v in [e for e in r['geom'] if isinstance(e, bmesh.types.BMVert)]:
        v.co.y = y1
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new('p'); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new('p', me)
    bpy.context.scene.collection.objects.link(o)
    bpy.context.view_layer.objects.active = o
    for ob in bpy.context.selected_objects: ob.select_set(False)
    o.select_set(True)
    if bev > 0:
        md = o.modifiers.new('b', 'BEVEL'); md.width = bev; md.segments = 4; md.limit_method = 'ANGLE'
        md.angle_limit = math.radians(40)
        bpy.ops.object.modifier_apply(modifier='b')
    return finish(o, mat, smooth=False)


def cyl(r, a, b, mat, verts=40, r2=None):
    """Цилиндр (или конус до радиуса r2) между точками a и b."""
    a, b = Vector(a), Vector(b)
    d = b - a
    if r2 is None:
        bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=r, depth=d.length)
    else:
        bpy.ops.mesh.primitive_cone_add(vertices=verts, radius1=r, radius2=r2, depth=d.length)
    o = bpy.context.object
    o.rotation_mode = 'QUATERNION'
    o.rotation_quaternion = Vector((0, 0, 1)).rotation_difference(d.normalized())
    o.location = (a + b) / 2
    bpy.ops.object.transform_apply(location=True, rotation=True)
    return finish(o, mat)


def tube(points, r, mat):
    """Гнутая трубка по точкам (кривая с толщиной)."""
    cu = bpy.data.curves.new('t', 'CURVE'); cu.dimensions = '3D'
    cu.bevel_depth = r; cu.bevel_resolution = 6; cu.use_fill_caps = True
    sp = cu.splines.new('BEZIER'); sp.bezier_points.add(len(points) - 1)
    for bp, p in zip(sp.bezier_points, points):
        bp.co = p; bp.handle_left_type = bp.handle_right_type = 'AUTO'
    o = bpy.data.objects.new('t', cu)
    bpy.context.scene.collection.objects.link(o)
    bpy.context.view_layer.objects.active = o
    for ob in bpy.context.selected_objects: ob.select_set(False)
    o.select_set(True)
    bpy.ops.object.convert(target='MESH')
    o = bpy.context.object
    return finish(o, mat)


def disk(cx, cz, r, y, mat, verts=48):
    """Плоский круг лицом к зрителю на глубине y."""
    bpy.ops.mesh.primitive_circle_add(vertices=verts, radius=r, fill_type='NGON', location=(cx, y, cz), rotation=(math.radians(90), 0, 0))
    return finish(bpy.context.object, mat, smooth=False)


def ring(cx, cz, R, r, y, mat):
    bpy.ops.mesh.primitive_torus_add(major_radius=R, minor_radius=r, major_segments=64, minor_segments=16,
                                     location=(cx, y, cz), rotation=(math.radians(90), 0, 0))
    return finish(bpy.context.object, mat)


def ellipse_pts(cx, cz, rx, rz, a0, a1, n=12):
    return [(cx + rx * math.cos(a0 + (a1 - a0) * i / n), cz + rz * math.sin(a0 + (a1 - a0) * i / n)) for i in range(n + 1)]


# ---------- приборы. Точки привязки (anchors) — мировые координаты для слоя лиц и эффектов.

def bath(wet):
    """Ванна на львиных лапах (канон): эмалевая чаша, скатанный борт, латунные лапы."""
    for y in (.07, -.09):                                                 # задние лапы прячутся за чашей
        for x in (-.26, .26):
            cyl(.035, (x, y, -.12), (x * 1.12, y, -.22), 'brass', r2=.055)
            for dx in (-.035, 0, .035):                                   # три «пальца» лапы
                bpy.ops.mesh.primitive_uv_sphere_add(radius=.032, location=(x * 1.12 + dx, y - .01, -.245)); finish(bpy.context.object, 'brass')
    pts = [(-.37, .17)] + ellipse_pts(-.22, -.02, .15, .16, math.pi, 1.5 * math.pi, 8)[1:] + \
        ellipse_pts(.22, -.02, .15, .16, 1.5 * math.pi, 2 * math.pi, 8) + [(.37, .17)]
    prism(pts, -.15, .15, 'enamel', bev=.05)
    rbox(-.40, .40, .15, .22, -.17, .17, .035, 'enamel')
    rbox(-.34, .34, .215, .226, -.12, .12, .03, 'water' if wet else 'inner', seg=3)
    return {'face': (0, -.15, .02), 'top': (0, 0, .24)}


def toilet(wet):
    """Унитаз-компакт сбоку: бачок у стены (слева, там вход), чаша вперёд, тёмное сиденье."""
    rbox(-.40, -.10, .02, .40, -.12, .12, .04, 'enamel')                 # бачок
    rbox(-.42, -.08, .39, .45, -.14, .14, .025, 'enamel')                # крышка бачка
    cyl(.045, (-.25, 0, .445), (-.25, 0, .47), 'chrome')                 # кнопка
    pts = [(-.14, .04), (.38, .04)] + ellipse_pts(.20, .04, .18, .20, 0, -.5 * math.pi, 10)[1:] + \
        [(.14, -.20), (.11, -.28), (.12, -.37), (.19, -.42), (.20, -.44), (-.18, -.44), (-.17, -.42), (-.12, -.37),
         (-.11, -.28), (-.12, -.18), (-.15, -.08)]
    prism(pts, -.13, .13, 'enamel', bev=.04)
    rbox(-.15, .40, .040, .072, -.14, .14, .015, 'seat')                 # сиденье с крышкой
    return {'face': (.19, -.13, -.05), 'top': (.15, 0, .10), 'wave': (.15, 0, .12)}


def sink(wet):
    """Раковина на тумбе: тумба с дверцами, стальная мойка, кран-гусак, гора посуды."""
    rbox(-.30, .38, -.46, .04, -.15, .15, .02, 'cream')
    for x0, x1 in ((-.26, .03), (.07, .34)):
        rbox(x0, x1, -.42, .00, -.165, -.14, .01, 'cream', seg=2)
    bpy.ops.mesh.primitive_uv_sphere_add(radius=.022, location=(.12, -.17, -.20)); finish(bpy.context.object, 'chrome')
    prism([(-.38, .14), (.46, .14), (.41, .04), (-.33, .04)], -.17, .17, 'chrome', bev=.012)
    for px, ang, k in ((-.15, -18, 0), (-.02, 8, 1), (.12, -6, 2)):
        bpy.ops.mesh.primitive_uv_sphere_add(radius=.12, location=(px, -.02, .15 + k * .025), rotation=(0, math.radians(ang), 0))
        o = bpy.context.object; o.scale = (1, .9, .28); bpy.ops.object.transform_apply(scale=True, rotation=True); finish(o, 'enamel')
    cyl(.035, (.33, .06, .14), (.33, .06, .22), 'chrome')
    tube([(.33, .06, .20), (.33, .06, .40), (.24, .06, .48), (.14, .06, .44)], .028, 'chrome')
    cyl(.022, (.34, .06, .27), (.40, .06, .30), 'chrome')                # рычаг
    return {'face': (-.11, -.17, -.20), 'spout': (.14, .06, .42), 'basin': (.14, .06, .15)}


def washer(wet):
    """Стиральная машина: корпус, пульт, люк с хромированным кольцом."""
    rbox(-.38, .38, -.46, .46, -.20, .20, .05, 'enamel')
    rbox(-.34, .34, .30, .42, -.215, -.19, .015, 'panel', seg=2)
    for x in (.18, .27):
        cyl(.035, (x, -.22, .36), (x, -.25, .36), 'chrome')
    ring(0, -.12, .21, .04, -.22, 'chrome')
    disk(0, -.12, .19, -.215, 'glassw' if wet else 'glass')
    return {'eyes': (0, -.22, .20), 'port': (0, -.22, -.12)}


def dryer(wet):
    """Полотенцесушитель-лесенка: две стойки, перекладины, кронштейны к стене; на перекладине — полотенце с лицом."""
    for x in (-.24, .24):
        cyl(.045, (x, 0, -.46), (x, 0, .46), 'chrome')
        for z in (-.46, .46):
            bpy.ops.mesh.primitive_uv_sphere_add(radius=.05, location=(x, 0, z)); finish(bpy.context.object, 'chrome')
        for z in (-.30, .30):
            cyl(.03, (x, 0, z), (x, .25, z), 'chrome')
    for z in (-.36, -.18, .00, .18, .36):
        cyl(.028, (-.24, 0, z), (.24, 0, z), 'chrome')
    # полотенце перекинуто через вторую сверху перекладину: передняя половина длиннее
    rbox(-.17, .17, -.20, .21, -.065, -.025, .03, 'towel')
    rbox(-.17, .17, .02, .21, .025, .06, .03, 'towel')
    cyl(.05, (-.17, 0, .195), (.17, 0, .195), 'towel')
    return {'face': (0, -.07, .04), 'top': (0, 0, .50), 'st1': (-.17, -.07, -.12), 'st2': (.17, -.07, -.12)}


def heater(wet):
    """Газовая колонка: эмалевый короб на стене, короткий дымоход, пульт снизу, окошко горелки, излив."""
    rbox(-.30, .30, -.34, .40, -.14, .14, .06, 'enamel')
    cyl(.12, (0, 0, .39), (0, 0, .56), 'alu')
    cyl(.15, (0, 0, .40), (0, 0, .45), 'alu')
    rbox(-.27, .27, -.32, -.18, -.155, -.13, .02, 'panel', seg=2)
    cyl(.045, (.15, -.15, -.25), (.15, -.19, -.25), 'knob')
    ring(0, .02, .115, .028, -.15, 'chrome')
    disk(0, .02, .105, -.145, 'hole')
    tube([(.26, 0, -.27), (.36, 0, -.27), (.40, 0, -.32), (.40, 0, -.40)], .03, 'chrome')
    return {'eyes': (0, -.15, .23), 'mouth': (0, -.15, .02), 'top': (0, 0, .56), 'spout': (.40, 0, -.42),
            'lamp': (-.15, -.15, -.25), 'bottom': (0, -.14, -.34)}


FIX = {'bath': bath, 'toilet': toilet, 'sink': sink, 'washer': washer, 'dryer': dryer, 'heater': heater}
AJ = os.path.join(OUT, 'anchors.json')
anchors = json.load(open(AJ)) if os.path.exists(AJ) else {}  # частичный прогон дополняет
for what, fn in FIX.items():
    if ONLY and what not in ONLY:
        continue
    for wet in (False, True):
        reset(); mats()
        an = fn(wet)
        sc = bpy.context.scene
        px = {}
        for k, p in an.items():
            u = world_to_camera_view(sc, sc.camera, Vector(p))
            px[k] = (round(u.x * RES, 1), round((1 - u.y) * RES, 1))
        anchors['%s_%s' % (what, 'wet' if wet else 'dry')] = px
        sc.render.filepath = os.path.join(OUT, '%s_%s.png' % (what, 'wet' if wet else 'dry'))
        bpy.ops.render.render(write_still=True)
        print('RENDER', what, wet)
with open(AJ, 'w') as f:
    json.dump(anchors, f, indent=1)
