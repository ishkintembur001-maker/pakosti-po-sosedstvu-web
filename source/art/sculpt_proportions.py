"""Reference silhouette sculpt, directly on existing Blender 4.3 animated meshes.

This is not a flat detail overlay: the original anatomical head and actual
cotton/flannel torso meshes receive controlled spatial deformations.
It preserves action clips, facial morph offsets, character hinges and UV data.
Order: groom_cast.py -> sculpt_proportions.py -> facial_details.py.
"""
import bpy
import math
import os
from mathutils import Vector

ROOT=os.path.abspath(os.path.join(os.path.dirname(__file__),".."))
MASTER=os.path.join(ROOT,"art","two_storey_faces.blend")
if not os.path.isfile(MASTER):
    raise RuntimeError("Missing editable anatomical cast master")
bpy.ops.wm.open_mainfile(filepath=MASTER)

def bell(value,center,width):
    return math.exp(-((value-center)/width)**2)

actors=[
    ("TricksterCharacter","Hero_Face_Anatomy","Petrol knit cotton",False),
    ("NeighborCharacter","Neighbor_Face_Anatomy","Burgundy plaid robe",True)
]
actions_before=tuple(sorted(action.name for action in bpy.data.actions))

for actor_name,face_name,cloth_name,is_neighbor in actors:
    actor=bpy.data.objects.get(actor_name)
    face=bpy.data.objects.get(face_name)
    if actor is None or face is None or face.parent!=actor or face.type!="MESH":
        raise RuntimeError("Original animated character missing: "+actor_name)
    if not face.data.shape_keys:
        raise RuntimeError("Shape-key anatomy missing: "+actor_name)
    keys=tuple(face.data.shape_keys.key_blocks)
    if tuple(k.name for k in keys)!=("Basis","Smile","Frown","Blink"):
        raise RuntimeError("Facial animation target names changed")
    basis=keys[0]
    morph_offsets=[
        [Vector(key.data[i].co)-Vector(basis.data[i].co) for key in keys[1:]]
        for i in range(len(basis.data))
    ]
    moved=0
    maximum=0.0
    for idx,vertex in enumerate(basis.data):
        x,y,z=Vector(vertex.co)
        absx=abs(x)
        side=1 if x>=0 else -1
        front=bell(y,-.28 if is_neighbor else -.26,.27)
        if is_neighbor:
            cheek=bell(absx,.27,.14)*bell(z,1.66,.145)*front
            brow=bell(absx,.17,.17)*bell(z,1.84,.075)*front
            jowl=bell(absx,.22,.16)*bell(z,1.49,.115)*front
            nose=bell(x,0,.09)*bell(z,1.66,.11)*front
            delta=Vector((side*(.040*cheek+.025*jowl),
                          -.033*cheek-.032*brow-.019*jowl-.018*nose,
                          .006*brow-.011*jowl))
        else:
            cheek=bell(absx,.22,.115)*bell(z,1.53,.12)*front
            tear=bell(absx,.153,.11)*bell(z,1.646,.068)*front
            nose=bell(x,0,.065)*bell(z,1.55,.095)*front
            jaw=bell(absx,.17,.13)*bell(z,1.41,.105)*front
            delta=Vector((side*(.023*cheek-.014*jaw),
                          -.034*cheek-.010*tear-.023*nose,
                          .007*cheek-.003*jaw))
        if delta.length<.00003:
            continue
        for shape in keys:
            shape.data[idx].co=Vector(shape.data[idx].co)+delta
        moved+=1
        maximum=max(maximum,delta.length)
    if moved<1000 or maximum>.11:
        raise RuntimeError("Unsafe anatomical sculpt on %s: %d / %.4f"%
                           (actor_name,moved,maximum))
    for i,base in enumerate(basis.data):
        base_pos=Vector(base.co)
        for key,offset in zip(keys[1:],morph_offsets[i]):
            if (Vector(key.data[i].co)-base_pos-offset).length>.00003:
                raise AssertionError("Morph changed during sculpt: "+actor_name)
    face.data.update()
    original_outfits=[
        ob for ob in actor.children
        if ob.type=="MESH" and not ob.data.shape_keys
        and any(mat and mat.name.startswith(cloth_name)
                for mat in ob.data.materials)
    ]
    if not original_outfits:
        raise RuntimeError("Primary cloth mesh missing: "+actor_name)
    reshaped=0
    for outfit in original_outfits:
        for vert in outfit.data.vertices:
            x,y,z=vert.co
            absx=abs(x)
            sign=1 if x>=0 else -1
            if is_neighbor:
                shoulders=bell(absx,.37,.23)*bell(z,1.17,.20)
                belly=bell(x,0,.37)*bell(z,.84,.24)*bell(y,-.25,.32)
                hips=bell(absx,.36,.16)*bell(z,.75,.12)
                delta=Vector((sign*(.030*shoulders+.011*hips),
                              -.050*belly-.012*shoulders,0))
            else:
                shoulders=bell(absx,.31,.17)*bell(z,1.14,.18)
                waist=bell(absx,.30,.15)*bell(z,.76,.17)
                chest=bell(x,0,.30)*bell(z,.95,.17)*bell(y,-.19,.22)
                delta=Vector((sign*(.020*shoulders-.016*waist),
                              -.018*chest,0))
            if delta.length>.0002:
                vert.co+=delta
                reshaped+=1
        outfit.data.update()
    if reshaped<40:
        raise RuntimeError("No meaningful wardrobe silhouette change: "+actor_name)
    actor["pakosti_art_direction"]="reference proportion sculpt v1"
    print("REFERENCE_SILHOUETTE_OK",actor_name,
          "face_vertices",moved,
          "max_deformation_m",round(maximum,5),
          "cloth_vertices",reshaped,flush=True)

if tuple(sorted(action.name for action in bpy.data.actions))!=actions_before:
    raise AssertionError("Existing animation actions changed unexpectedly")
bpy.ops.wm.save_as_mainfile(filepath=MASTER)
print("REFERENCE_SCULPT_SAVED",MASTER,flush=True)
