"""CC0 anatomical face replacement and fitted character accessories.
Run after refine_cast.py. The small, unmodified CC0 source collection is committed.
Optional PAKOSTI_HUMAN_BASE points to the full official Blender Studio asset bundle.
"""
import bpy,bmesh,os,math,struct,json
import numpy as np
from mathutils import Vector
from mathutils.bvhtree import BVHTree
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SMALL=os.path.join(ROOT,'art/source/stylized_head_cc0.blend')
LIB=os.environ.get('PAKOSTI_HUMAN_BASE',SMALL)
bpy.ops.wm.open_mainfile(filepath=os.path.join(ROOT,'art/two_storey_game.blend'))
with bpy.data.libraries.load(LIB,link=False) as (src,dst):dst.collections=['Head - Stylized']
collection=dst.collections[0];bpy.context.scene.collection.children.link(collection);bpy.context.view_layer.update()
if not os.path.exists(SMALL):
 os.makedirs(os.path.dirname(SMALL),exist_ok=True);bpy.data.libraries.write(SMALL,{collection},compress=True)
base=bpy.data.objects['GEO-head_stylized'];inv=base.matrix_world.inverted();head_data=base.data.copy()
eye_sources=[(inv@o.matrix_world.copy(),o.data.copy()) for o in collection.all_objects if '.eye.' in o.name]
def lin(v):return v/12.92 if v<.04045 else ((v+.055)/1.055)**2.4
def rgb(h):return tuple(lin(int(h[i:i+2],16)/255) for i in (0,2,4))
def mat(name,h,rough=.7):
 m=bpy.data.materials.new(name);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*rgb(h),1);p.inputs['Roughness'].default_value=rough;return m
skin=mat('Anatomical skin complexion','ffffff',.76)
color=skin.node_tree.nodes.new('ShaderNodeVertexColor');color.layer_name='Complexion';mix=skin.node_tree.nodes.new('ShaderNodeMixRGB');mix.blend_type='MULTIPLY';mix.inputs[0].default_value=1;mix.inputs[2].default_value=(*rgb('d7ab92'),1);skin.node_tree.links.new(color.outputs['Color'],mix.inputs[1]);skin.node_tree.links.new(mix.outputs['Color'],skin.node_tree.nodes.get('Principled BSDF').inputs['Base Color'])
hair=mat('Groomed chestnut','493025',.8);cap=mat('Woven red cap','ad3e34',.87);ivory=mat('Cap canvas panels','d4c9b4',.91)
def prune(obj,predicate):
 bm=bmesh.new();bm.from_mesh(obj.data);bmesh.ops.delete(bm,geom=[f for f in bm.faces if predicate(f.calc_center_median())],context='FACES');bm.to_mesh(obj.data);bm.free()
def finish_mesh(o,sub=0):
 bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.00001);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(o.data);bm.free()
 for p in o.data.polygons:p.use_smooth=True
 if sub:
  mod=o.modifiers.new('Smooth sculpt topology','SUBSURF');mod.levels=sub;bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=mod.name)
def curve_mesh(name,points,radius,material,parent,radii=None):
 c=bpy.data.curves.new(name,'CURVE');c.dimensions='3D';c.bevel_depth=radius;c.bevel_resolution=3;c.resolution_u=16;s=c.splines.new('BEZIER');s.bezier_points.add(len(points)-1)
 for i,(b,p) in enumerate(zip(s.bezier_points,points)):
  b.co=p;b.handle_left_type='AUTO';b.handle_right_type='AUTO';b.radius=radii[i] if radii else 1
 o=bpy.data.objects.new(name,c);bpy.context.collection.objects.link(o);o.parent=parent;c.materials.append(material);bpy.context.view_layer.objects.active=o;o.select_set(True);bpy.ops.object.convert(target='MESH');o.select_set(False);return o
for name in ['TricksterCharacter','NeighborCharacter']:
 root=bpy.data.objects[name];enemy=name.startswith('Neighbor')
 for child in list(root.children):
  if child.type!='MESH':continue
  name_mat=child.data.materials[0].name
  if name_mat in ['Warm peach skin','Warm cheeks','Hazel irises','Deep pupils']:bpy.data.objects.remove(child,do_unlink=True)
  elif name_mat=='Warm white':
   if enemy:bpy.data.objects.remove(child,do_unlink=True)
   else:prune(child,lambda p:p.z>1.3)
  elif name_mat=='Chestnut hair':
   # Old facial markings do not fit the new topology. Keep only the neighbor's quiff.
   if enemy:prune(child,lambda p:p.z<2.03);finish_mesh(child,1)
   else:bpy.data.objects.remove(child,do_unlink=True)
  elif not enemy and name_mat=='Carmine canvas':prune(child,lambda p:not (p.y>.25 and p.z<1.90))
 sx,sy,sz=(3.12,2.60,2.62) if enemy else (2.72,2.45,2.40)
 ez=1.75 if enemy else 1.64;oz=ez-.1726*sz
 face=bpy.data.objects.new(('Neighbor' if enemy else 'Hero')+'_Face_Anatomy',head_data.copy());bpy.context.collection.objects.link(face);face.parent=root;face.data.materials.clear();face.data.materials.append(skin)
 for v in face.data.vertices:
  co=v.co.copy()
  if enemy:
   co.x*=1+.12*math.exp(-((co.z-.09)/.075)**2)
   if co.y<-.115 and abs(co.x)<.04:co.y-=.012*math.exp(-((co.z-.16)/.05)**2)
  v.co=(co.x*sx,co.y*sy,co.z*sz+oz)
 colors=face.data.color_attributes.new(name='Complexion',type='FLOAT_COLOR',domain='POINT')
 for v in face.data.vertices:
  x,y,z=v.co.x/sx,v.co.y/sy,(v.co.z-oz)/sz
  blush=math.exp(-((abs(x)-.07)/.035)**2-((z-.14)/.035)**2)*max(0,min(1,(-y-.025)/.05))
  lip=math.exp(-((z-.087)/.013)**2-(x/.056)**6)*max(0,min(1,(-y-.08)/.03))
  c=np.array(rgb('d4a084' if enemy else 'e2b397'));c=c*(1-blush*.12)+np.array(rgb('d08f81'))*blush*.12;c=c*(1-lip*.30)+np.array(rgb('b97c73'))*lip*.30
  c=np.clip(c/np.array(rgb('d4a084' if enemy else 'e2b397')),.55,1);colors.data[v.index].color=(*c,1)
 finish_mesh(face,1)
 bvh=BVHTree.FromPolygons([v.co for v in face.data.vertices],[list(p.vertices) for p in face.data.polygons])
 def surface(x,z,extra=.018):
  hit=bvh.ray_cast(Vector((x,-2,z)),Vector((0,1,0)),4)[0]
  return (x,(hit.y if hit else -.30)-extra,z)
 # Eyebrows are tapered ribbons/curves placed on the actual forehead surface.
 for side in [-1,1]:
  points=[]
  for i in range(6):
   t=i/5;x=side*(.07+t*.19);z=ez+(.11+.105*t if enemy else .17+.035*math.sin(t*math.pi));points.append(surface(x,z,.022))
  curve_mesh('Frowning eyebrow' if enemy else 'Jaunty eyebrow',points,.030 if enemy else .022,hair,root,[.65,1,1,.95,.7,.18])
 if enemy:
  for side in [-1,1]:
   points=[surface(side*x,ez-.135+dz,.035) for x,dz in [(0,0),(.075,-.005),(.15,-.025),(.22,.005)]]
   curve_mesh('Swept moustache',points,.045,hair,root,[.65,1,.8,.12])
 # Skull-conforming cap or side hair: no old crown intersecting the forehead.
 scalp=bpy.data.objects.new('Fitted_cap' if not enemy else 'Receding_side_hair',face.data.copy());bpy.context.collection.objects.link(scalp);scalp.parent=root
 for a in list(scalp.data.color_attributes):scalp.data.color_attributes.remove(a)
 if not enemy:prune(scalp,lambda p:p.z<ez+.19)
 else:prune(scalp,lambda p:not(abs(p.x)>.25 and p.y>-.11 and p.z>ez+.02))
 scalp.data.materials.clear();scalp.data.materials.append(cap if not enemy else hair)
 if not enemy:
  scalp.data.materials.append(ivory)
  for p in scalp.data.polygons:
   center=p.center;p.material_index=1 if abs(center.x)>.22 and center.y>.0 else 0
 for v in scalp.data.vertices:v.co+=v.normal*.018
 solid=scalp.modifiers.new('Tailored surface thickness','SOLIDIFY');solid.thickness=.012;bpy.context.view_layer.objects.active=scalp;bpy.ops.object.modifier_apply(modifier=solid.name)
 if not enemy:
  # Swept forelocks sit between forehead and cap, with tapered, softened tips.
  for k in range(7):
   x=-.25+k*.065;points=[surface(x,ez+.245,.045),surface(x+.065,ez+.225,.055),surface(x+.11,ez+.155,.045)]
   curve_mesh('Swept forelock',points,.054,hair,root,[1,.85,.08])
 # Proper eye geometry behind the eyelids; radial iris fibers in a packed texture.
 for i,(transform,data) in enumerate(eye_sources):
  e=bpy.data.objects.new(('Neighbor' if enemy else 'Hero')+'_Eye_'+str(i),data.copy());bpy.context.collection.objects.link(e);e.parent=root;center=transform.translation
  for v in e.data.vertices:
   p=transform@v.co;v.co=(p.x*sx,p.y*sy,p.z*sz+oz)
  uv=e.data.uv_layers.active or e.data.uv_layers.new(name='IrisUV')
  for poly in e.data.polygons:
   poly.use_smooth=True
   for li in poly.loop_indices:
    p=e.data.vertices[e.data.loops[li].vertex_index].co;uv.data[li].uv=((p.x/sx-center.x)/.076+.5,((p.z-oz)/sz-center.z)/.076+.5)
  N=256;yy,xx=np.mgrid[0:N,0:N].astype(float);u=(xx+.5)/N-.5;v=(yy+.5)/N-.5;r=np.sqrt(u*u+v*v);angle=np.arctan2(v,u)
  arr=np.ones((N,N,4),np.float32);arr[:,:,:3]=rgb('f4eee3');fibers=.83+.12*np.sin(angle*67+r*140)+.05*np.sin(angle*117-r*35)
  iris=np.array(rgb('78603b' if enemy else '8b662f'))[None,None,:]*fibers[:,:,None];iris*=np.clip((.225-r)*45,.3,1)[:,:,None];arr[:,:,:3][r<.225]=iris[r<.225];arr[:,:,:3][r<.085]=rgb('111817')
  im=bpy.data.images.new(e.name+'_Iris',width=N,height=N);im.colorspace_settings.name='Linear Rec.709';im.pixels.foreach_set(arr.ravel());im.pack()
  m=mat(e.name+'_Surface','ffffff',.28);tex=m.node_tree.nodes.new('ShaderNodeTexImage');tex.image=im;m.node_tree.links.new(tex.outputs['Color'],m.node_tree.nodes.get('Principled BSDF').inputs['Base Color']);e.data.materials.clear();e.data.materials.append(m)
 # Actual morph targets, distinct from the nine articulated body transform clips.
 face.shape_key_add(name='Basis')
 for key in ['Smile','Frown','Blink']:
  shape=face.shape_key_add(name=key)
  for j,v in enumerate(face.data.vertices):
   x,y,z=v.co;local_z=(z-oz)/sz
   mouth=math.exp(-((local_z-.087)/.020)**2)*max(0,min(1,(-y-.18)/.12));corners=math.exp(-((abs(x)-.13)/.085)**2)
   if key=='Smile':shape.data[j].co.z+=.04*mouth*corners
   elif key=='Frown':shape.data[j].co.z-=.04*mouth*corners
   else:
    eye=math.exp(-((abs(x)-.044*sx)/(.038*sx))**4)*max(0,min(1,(-y-.15)/.09));upper=math.exp(-((local_z-.195)/.022)**2);lower=math.exp(-((local_z-.15)/.017)**2)
    shape.data[j].co.z+=eye*(-.065*upper+.025*lower)
 face['source']='Blender Studio Human Base Meshes v1.4.1, CC0'
 if not enemy:root.scale=(.88,.88,.88)
 # Match the reference's long teal hoodie; retain the woven normal map.
 if not enemy:
  cotton=None
  for o in root.children:
   if o.type!='MESH':continue
   for material in o.data.materials:
    if material and 'woven_fabric' in material.name:
     cotton=material;p=material.node_tree.nodes.get('Principled BSDF')
     for link in list(p.inputs['Base Color'].links):material.node_tree.links.remove(link)
     p.inputs['Base Color'].default_value=(*rgb('237b88'),1)
  if cotton:
   for limb in root.children:
    if not limb.name.startswith('Arm_'):continue
    for o in limb.children:
     if o.type!='MESH' or not o.data.materials or o.data.materials[0].name!='Warm peach skin':continue
     o.data.materials.append(cotton);slot=len(o.data.materials)-1
     for poly in o.data.polygons:
      if poly.center.z>-.43:poly.material_index=slot
for o in list(collection.all_objects):bpy.data.objects.remove(o,do_unlink=True)
bpy.data.collections.remove(collection)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ROOT,'art/two_storey_faces.blend'))
for o in bpy.data.objects:
 if o.animation_data:
  for track in o.animation_data.nla_tracks:track.mute=False
  if o.animation_data.nla_tracks:o.animation_data.action=o.animation_data.nla_tracks[0].strips[0].action
path=os.path.join(ROOT,'assets/models/two_storey.glb')
bpy.ops.export_scene.gltf(filepath=path,export_format='GLB',export_animations=True,export_animation_mode='NLA_TRACKS',export_nla_strips=True,export_force_sampling=True,export_frame_range=False,export_cameras=False,export_lights=False,export_morph=True)
# glTF's COLOR_0 already carries the complexion. The complexion is a near-white modulation; use one well-defined base skin tint.
b=open(path,'rb').read();n=struct.unpack_from('<I',b,12)[0];doc=json.loads(b[20:20+n]);tail=b[20+n:]
for m in doc['materials']:
 if m.get('name')=='Anatomical skin complexion':m['pbrMetallicRoughness']['baseColorFactor']=[*rgb('d7ab92'),1]
j=json.dumps(doc,separators=(',',':')).encode();j+=b' '*((-len(j))%4);open(path,'wb').write(struct.pack('<III',0x46546c67,2,20+len(j)+len(tail))+struct.pack('<II',len(j),0x4e4f534a)+j+tail)
print('CC0_ANATOMICAL_CAST_EXPORTED')
