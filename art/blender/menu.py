# art/blender/menu.py — фон главного меню (подвал): кирпичная стена с объёмными кирпичами, трубы под потолком с муфтами,
# стояк с фланцами, большой красный вентиль «главный вентиль дома», лампочка на шнуре. Тот же мультяшный рендер.
# Луч света, бирка, логотип и Лапидус — слоем поверх (art/export_ui.py). 1 ед. = 100 px, холст 1920×1080.
# Запуск: blender -b -P art/blender/menu.py -- <выход.png>
import bpy, math, sys
from mathutils import Vector

OUT = sys.argv[sys.argv.index('--') + 1]
bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene
sc.render.engine = 'BLENDER_EEVEE'
sc.render.resolution_x, sc.render.resolution_y = 1920, 1080
sc.view_settings.view_transform = 'Standard'
sc.eevee.use_soft_shadows = True
sc.eevee.use_gtao = True
sc.eevee.gtao_distance = .8
sc.render.use_freestyle = True
sc.render.line_thickness_mode = 'ABSOLUTE'
sc.render.line_thickness = 1.0
ls = sc.view_layers[0].freestyle_settings.linesets.new('ol')
ls.select_by_visibility = ls.select_by_edge_types = True
ls.select_silhouette, ls.select_border, ls.select_crease, ls.select_external_contour = True, False, False, True
ls.select_by_collection = True
wallc = bpy.data.collections.new('wall'); sc.collection.children.link(wallc)
ls.collection, ls.collection_negation = wallc, 'EXCLUSIVE'
ls.linestyle = bpy.data.linestyles.new('ol'); ls.linestyle.color = (0.024, 0.016, 0.010); ls.linestyle.thickness = 5
for other in sc.view_layers[0].freestyle_settings.linesets:
    if other.linestyle is None:
        other.linestyle = ls.linestyle
cam = bpy.data.objects.new('cam', bpy.data.cameras.new('cam'))
cam.data.type, cam.data.ortho_scale = 'ORTHO', 19.2
cam.location, cam.rotation_euler = (0, -30, 0), (math.radians(90), 0, 0)
sc.collection.objects.link(cam); sc.camera = cam
sun = bpy.data.objects.new('sun', bpy.data.lights.new('sun', 'SUN'))
sun.data.energy, sun.data.angle = 3.0, math.radians(8)
sun.rotation_euler = Vector((0, 0, -1)).rotation_difference(Vector((.30, .80, -.52)).normalized()).to_euler()
sc.collection.objects.link(sun)
sc.world = bpy.data.worlds.new('w'); sc.world.use_nodes = True
sc.world.node_tree.nodes['Background'].inputs[1].default_value = 0.0


def X(px): return (px - 960) / 100
def Z(py): return -(py - 540) / 100


def lin(c):
    c = c.lstrip('#'); v = [int(c[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    return tuple(x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in v)


def toon(dark, mid, light, spec):
    m = bpy.data.materials.new('t'); m.use_nodes = True
    nt = m.node_tree; nt.nodes.clear()
    out, dif, s2r, ramp, emi = (nt.nodes.new(t) for t in ('ShaderNodeOutputMaterial', 'ShaderNodeBsdfDiffuse', 'ShaderNodeShaderToRGB',
                                                          'ShaderNodeValToRGB', 'ShaderNodeEmission'))
    cr = ramp.color_ramp; cr.interpolation = 'CONSTANT'
    cr.elements[0].position, cr.elements[0].color = 0.0, (*lin(dark), 1)
    cr.elements[1].position, cr.elements[1].color = 0.18, (*lin(mid), 1)
    e = cr.elements.new(0.55); e.color = (*lin(light), 1)
    e = cr.elements.new(0.92); e.color = (*lin(spec), 1)
    nt.links.new(dif.outputs[0], s2r.inputs[0]); nt.links.new(s2r.outputs[0], ramp.inputs[0])
    nt.links.new(ramp.outputs[0], emi.inputs[0]); nt.links.new(emi.outputs[0], out.inputs[0])
    return m


def put(o, m, smooth=True, coll=None):
    if smooth:
        for p in o.data.polygons: p.use_smooth = True
    o.data.materials.append(m)
    if coll:
        for c in list(o.users_collection): c.objects.unlink(o)
        coll.objects.link(o)
    return o


def cyl(r, a, b, m, verts=48):
    a, b = Vector(a), Vector(b); d = b - a
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=r, depth=d.length)
    o = bpy.context.object; o.rotation_mode = 'QUATERNION'
    o.rotation_quaternion = Vector((0, 0, 1)).rotation_difference(d.normalized()); o.location = (a + b) / 2
    bpy.ops.object.transform_apply(location=True, rotation=True)
    return put(o, m)


IRON = toon('#22262A', '#454C54', '#6E7781', '#A3ADB8')
RED = toon('#7E2116', '#C83E2C', '#E2604B', '#F59A83')
BRASS = toon('#7A5414', '#C9962E', '#EBC260', '#FFF3C2')

# стена: кирпич с фасками (шов, светлая кромка сверху, тёмная снизу) × тень
m = bpy.data.materials.new('wall'); m.use_nodes = True; nt = m.node_tree; nt.nodes.clear()
geo = nt.nodes.new('ShaderNodeNewGeometry'); sep = nt.nodes.new('ShaderNodeSeparateXYZ'); nt.links.new(geo.outputs['Position'], sep.inputs[0])


def mth(op, a, b=None):
    n_ = nt.nodes.new('ShaderNodeMath'); n_.operation = op
    for i, v in enumerate((a, b)):
        if v is None: continue
        if isinstance(v, (int, float)): n_.inputs[i].default_value = v
        else: nt.links.new(v, n_.inputs[i])
    return n_.outputs[0]


def mixc(f, c0, c1):
    n_ = nt.nodes.new('ShaderNodeMixRGB'); nt.links.new(f, n_.inputs[0])
    for i, c in ((1, c0), (2, c1)):
        if isinstance(c, tuple): n_.inputs[i].default_value = c
        else: nt.links.new(c, n_.inputs[i])
    return n_.outputs[0]


BW, BH = 1.5, .64                                     # кирпич 150×64 px (как прежде)
row = mth('FLOOR', mth('DIVIDE', mth('SUBTRACT', 0, sep.outputs[2]), BH))
shift = mth('MULTIPLY', mth('MODULO', row, 2), .5)
u = mth('FRACT', mth('ADD', mth('DIVIDE', sep.outputs[0], BW), shift))
v = mth('FRACT', mth('DIVIDE', mth('SUBTRACT', 0, sep.outputs[2]), BH))       # 0 — верх кирпича
gu, gv = .02 / BW * 1.5, .03 / BH * 1.5
e_t, e_b, e_l, e_r = v, mth('SUBTRACT', 1, v), mth('MULTIPLY', u, BW / BH), mth('MULTIPLY', mth('SUBTRACT', 1, u), BW / BH)
ml = mth('MINIMUM', e_t, e_l); md = mth('MINIMUM', e_b, e_r); e = mth('MINIMUM', ml, md)
noi = nt.nodes.new('ShaderNodeTexNoise'); noi.inputs['Scale'].default_value = .9
cmb = nt.nodes.new('ShaderNodeCombineXYZ'); nt.links.new(row, cmb.inputs[1]); nt.links.new(mth('FLOOR', mth('ADD', mth('DIVIDE', sep.outputs[0], BW), shift)), cmb.inputs[0])
nt.links.new(cmb.outputs[0], noi.inputs['Vector'])
brick = mixc(noi.outputs['Fac'], (*lin('#3A2E28'), 1), (*lin('#4A3B31'), 1))
bev = mixc(mth('LESS_THAN', ml, md), (*lin('#241C18'), 1), (*lin('#5A493E'), 1))
col = mixc(mth('LESS_THAN', e, .07), brick, bev)
col = mixc(mth('LESS_THAN', e, .03), col, (*lin('#1C1714'), 1))
dif = nt.nodes.new('ShaderNodeBsdfDiffuse'); s2r = nt.nodes.new('ShaderNodeShaderToRGB'); bwn = nt.nodes.new('ShaderNodeRGBToBW')
ramp = nt.nodes.new('ShaderNodeValToRGB'); ramp.color_ramp.interpolation = 'CONSTANT'
ramp.color_ramp.elements[0].color = (.55, .55, .55, 1); ramp.color_ramp.elements[1].position = .3; ramp.color_ramp.elements[1].color = (1, 1, 1, 1)
nt.links.new(dif.outputs[0], s2r.inputs[0]); nt.links.new(s2r.outputs[0], bwn.inputs[0]); nt.links.new(bwn.outputs[0], ramp.inputs[0])
mm = nt.nodes.new('ShaderNodeMixRGB'); mm.blend_type = 'MULTIPLY'; mm.inputs[0].default_value = 1
nt.links.new(col, mm.inputs[1]); nt.links.new(ramp.outputs[0], mm.inputs[2])
em = nt.nodes.new('ShaderNodeEmission'); out = nt.nodes.new('ShaderNodeOutputMaterial')
nt.links.new(mm.outputs[0], em.inputs[0]); nt.links.new(em.outputs[0], out.inputs[0])
bpy.ops.mesh.primitive_plane_add(size=1, location=(0, 1.0, 0), rotation=(math.radians(90), 0, 0))
w = bpy.context.object; w.scale = (24, 14, 1); put(w, m, smooth=False, coll=wallc)

# трубы под потолком с муфтами
for py_, r in ((165, .29), (242, .18)):
    cyl(r, (X(-40), 0, Z(py_)), (X(1960), 0, Z(py_)), IRON)
for xk in (275, 735, 1195, 1655):
    cyl(.36, (X(xk - 15), 0, Z(165)), (X(xk + 15), 0, Z(165)), IRON)
# стояк, фланцы, вентиль
cyl(.48, (X(378), -.4, Z(250)), (X(378), -.4, Z(1110)), IRON)
for fy in (350, 1030):
    cyl(.66, (X(378), -.4, Z(fy - 20)), (X(378), -.4, Z(fy + 20)), IRON)
    for bx in (-.5, .5):
        bpy.ops.mesh.primitive_uv_sphere_add(radius=.07, location=(X(378) + bx, -1.0, Z(fy)))
        put(bpy.context.object, IRON)
cyl(.10, (X(378), -.8, Z(640)), (X(378), -1.6, Z(640)), IRON)
bpy.ops.mesh.primitive_torus_add(major_radius=1.6, minor_radius=.17, major_segments=96, minor_segments=20,
                                 location=(X(378), -1.7, Z(640)), rotation=(math.radians(90), 0, 0))
put(bpy.context.object, RED)
for k in range(6):
    a = math.pi / 3 * k + .26
    cyl(.10, (X(378), -1.7, Z(640)), (X(378) + math.cos(a) * 1.58, -1.7, Z(640) - math.sin(a) * 1.58), RED, 20)
bpy.ops.mesh.primitive_uv_sphere_add(radius=.44, location=(X(378), -1.75, Z(640))); bpy.context.object.scale = (1, .6, 1)
bpy.ops.object.transform_apply(scale=True); put(bpy.context.object, BRASS)
# лампочка: шнур и колба (светится)
cyl(.025, (0, -.2, Z(-10)), (0, -.2, Z(64)), IRON, 12)
cyl(.10, (0, -.2, Z(58)), (0, -.2, Z(70)), BRASS, 24)
lm = bpy.data.materials.new('bulb'); lm.use_nodes = True
bnt = lm.node_tree; bnt.nodes.clear()
be = bnt.nodes.new('ShaderNodeEmission'); be.inputs[0].default_value = (*lin('#FFF3C4'), 1); bo = bnt.nodes.new('ShaderNodeOutputMaterial')
bnt.links.new(be.outputs[0], bo.inputs[0])
bpy.ops.mesh.primitive_uv_sphere_add(radius=.30, location=(0, -.2, Z(92))); put(bpy.context.object, lm)

sc.render.filepath = OUT
bpy.ops.render.render(write_still=True)
print('MENU', OUT)
