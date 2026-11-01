"""Game-ready sculpted freckles on the anatomical boy's face.

Creates ONE opaque mesh with multiple pigmented skin tones, sampled from the
underlying skin topology. Never changes morph-target face vertices, action clips,
skin shader, eyebrow meshes, camera, or gameplay.
"""
import bpy
import math
import os
import random
from mathutils import Vector
from mathutils.bvhtree import BVHTree

ROOT=os.path.abspath(os.path.join(os.path.dirname(__file__),".."))
MASTER=os.path.join(ROOT,"art","two_storey_faces.blend")
bpy.ops.wm.open_mainfile(filepath=MASTER)

hero=bpy.data.objects.get("TricksterCharacter")
face=bpy.data.objects.get("Hero_Face_Anatomy")
if hero is None or face is None or face.parent!=hero:
    raise RuntimeError("Missing known anatomical hero mesh")
if bpy.data.objects.get("Hero_FreckleClusters") is not None:
    raise RuntimeError("Freckles already exist; refusing duplicate")
if face.type!="MESH" or not face.data.shape_keys:
    raise RuntimeError("Face shape keys not available")
shape_names=tuple(k.name for k in face.data.shape_keys.key_blocks)
if shape_names!=("Basis","Smile","Frown","Blink"):
    raise RuntimeError("Unexpected facial morph target changes: "+str(shape_names))
anim_names=tuple(sorted(a.name for a in bpy.data.actions))
mesh=face.data
vertices=[v.co[:] for v in mesh.vertices]
polygons=[tuple(p.vertices) for p in mesh.polygons]
bvh=BVHTree.FromPolygons(vertices,polygons,all_triangles=False)
rng=random.Random(3042026)
tones=[
    ("Freckle - honey",(.43,.215,.117)),
    ("Freckle - light sienna",(.54,.300,.179)),
    ("Freckle - warm umber",(.36,.181,.106)),
]
materials=[]
for name,srgb in tones:
    m=bpy.data.materials.get(name)
    if m is None:
        m=bpy.data.materials.new(name)
        m.use_nodes=True
        p=m.node_tree.nodes.get("Principled BSDF")
        def linear(v):
            return v/12.92 if v<.04045 else ((v+.055)/1.055)**2.4
        p.inputs["Base Color"].default_value=(*[linear(c) for c in srgb],1)
        p.inputs["Roughness"].default_value=.86
        p.inputs["Metallic"].default_value=0.0
    materials.append(m)

def skin_y(x,z):
    hit,normal,face_idx,distance=bvh.ray_cast(Vector((x,-2,z)),Vector((0,1,0)),4.0)
    return hit.y if hit is not None else None

verts=[]
faces=[]
tone_ids=[]
radii=[]
def freckle(x,z,radius,tone,asym=1.0):
    y=skin_y(x,z)
    if y is None:
        return False
    count=9
    start=len(verts)
    verts.append((x,y-.0035,z))
    # Freckle edges are deliberately irregular and follow cheek topology.
    for k in range(count):
        a=math.tau*k/count
        fringe=1+.11*math.sin(k*2.6+x*53)
        xx=x+radius*math.cos(a)*fringe
        zz=z+radius*asym*math.sin(a)*fringe
        yy=skin_y(xx,zz)
        if yy is None: yy=y
        verts.append((xx,yy-.0030,zz))
    for k in range(count):
        faces.append((start,start+1+k,start+1+(k+1)%count))
        tone_ids.append(tone)
    radii.append(radius)
    return True

for side in (-1,1):
    for i in range(26):
        # Warm diffuse freckles grouped below the eyes, not random facial noise.
        x=side*(.128+.133*rng.random())
        z=1.522+.094*rng.random()+.012*math.sin(i*1.7)
        size=.0045+.004*rng.random()
        freckle(x,z,size,(i+int(rng.random()*3))%len(materials),.70+.45*rng.random())
for i in range(8):
    x=(rng.random()-.5)*.137
    z=1.591+.034*rng.random()
    freckle(x,z,.0032+.0033*rng.random(),i%3,.84)

if len(radii)<34:
    raise RuntimeError("Too few projected freckles "+str(len(radii)))
m=bpy.data.meshes.new("Hero_FreckleClusters_Geometry")
m.from_pydata(verts,[],faces)
m.update()
for material in materials:
    m.materials.append(material)
for p,tone in zip(m.polygons,tone_ids):
    p.material_index=tone
    p.use_smooth=False
uv=m.uv_layers.new(name="PigmentUV")
for poly in m.polygons:
    for loop_id in poly.loop_indices:
        v=m.vertices[m.loops[loop_id].vertex_index].co
        uv.data[loop_id].uv=((v.x+.5),v.z/2.2)
col=m.color_attributes.new(name="Col",type="BYTE_COLOR",domain="POINT")
for value in col.data:
    value.color=(1,1,1,1)
detail=bpy.data.objects.new("Hero_FreckleClusters",m)
bpy.context.collection.objects.link(detail)
detail.parent=hero
detail["pakosti_skin_details"]="projected opaque freckle clusters, no billboard decals"
if tuple(sorted(a.name for a in bpy.data.actions))!=anim_names:
    raise RuntimeError("Animation actions unexpectedly changed")
if tuple(k.name for k in face.data.shape_keys.key_blocks)!=shape_names:
    raise RuntimeError("Hero facial expressions unexpectedly changed")
if len(m.polygons)>900:
    raise RuntimeError("Freckle decals exceed mobile polygon budget")
bpy.ops.wm.save_as_mainfile(filepath=MASTER)
print("FRECKLED_HERO_OK",len(radii),"spots",len(m.polygons),"tris",flush=True)
