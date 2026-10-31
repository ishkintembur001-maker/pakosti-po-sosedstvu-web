"""Non-destructive cast pass on the exact Blendstra GLB; bake named transform clips.
Run with Blender 4.3: blender -b --python art/refine_cast.py
Input retained as two_storey_base.glb. Produces editable master + GLB with animations.
"""
import bpy,math,os,bmesh,gzip,hashlib
from mathutils import Vector
ROOT=os.path.abspath(os.path.join(os.path.dirname(__file__),'..'))
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
base=os.path.join(ROOT,'assets/models/two_storey_base.glb')
if not os.path.exists(base):
 with gzip.open(base+'.gz','rb') as src,open(base,'wb') as dst:dst.write(src.read())
assert hashlib.sha256(open(base,'rb').read()).hexdigest()=='fc7a8ab2c1895b7a3e6e1b98686b1331d14a4c8ac3bf68373636fbac4ca80b6c'
bpy.ops.import_scene.gltf(filepath=base)
scene=bpy.context.scene;scene.render.fps=30
for name in ['TricksterCharacter','NeighborCharacter']:
 root=bpy.data.objects[name];enemy=name.startswith('Neighbor');z=1.69 if enemy else 1.58
 root.rotation_euler=(0,0,0)
 for child in root.children:
  if child.type!='MESH':continue
  material=child.data.materials[0].name
  if material=='Warm peach skin':
   bpy.context.view_layer.objects.active=child
   bm=bmesh.new();bm.from_mesh(child.data)
   bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.00001)
   bmesh.ops.holes_fill(bm,edges=[e for e in bm.edges if e.is_boundary],sides=0)
   bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
   bm.to_mesh(child.data);bm.free();child.data.update()
   # Fuse the head, cheeks, nose and ears into a single skin surface.
   remesh=child.modifiers.new('Continuous sculpted skin','REMESH');remesh.mode='VOXEL';remesh.voxel_size=.008;remesh.use_smooth_shade=True
   bpy.ops.object.modifier_apply(modifier=remesh.name)
   smooth=child.modifiers.new('Relax anatomical joins','SMOOTH');smooth.factor=.7;smooth.iterations=5;bpy.ops.object.modifier_apply(modifier=smooth.name)
   dec=child.modifiers.new('Game mesh reduction','DECIMATE');dec.ratio=.45;bpy.ops.object.modifier_apply(modifier=dec.name);child.data.validate(clean_customdata=True)
  if material in ['Warm white','Hazel irises','Deep pupils']:
   # Keep drawstring/cap/laces intact; reduce each eye around its own socket.
   for v in child.data.vertices:
    if z-.13<v.co.z<z+.2 and v.co.y<-.20:
     center=Vector(((-1 if v.co.x<0 else 1)*(.154 if enemy else .132),-.265,z+.06))
     d=v.co-center;v.co=center+Vector((d.x*.88,d.y*.9,d.z*.88))
 # Named clips are real glTF animations targeting articulated shoulder/hip pivots.
 limbs=[c for c in root.children if c.type=='EMPTY' and c.name.startswith(('Arm_','Legs_'))]
 for limb in limbs:limb.animation_data_clear();limb.rotation_mode='XYZ';limb.rotation_euler=(0,0,0)
 clips=[('idle',60,0),('walk',30,.44),('sneak',48,.25),('run',22,.72),('pickup',36,0),('plant_trap',48,0),('react_slip',60,0),('react_surprise',60,0),('celebrate',60,0)]
 for clip,frames,amplitude in clips:
  for limb in limbs:
   action=bpy.data.actions.new(name+'_'+limb.name+'_'+clip);limb.animation_data_create();limb.animation_data.action=action
   leg=limb.name.startswith('Legs');sign=1 if limb.name.startswith(('Legs_L','Arm_R')) else -1
   for frame in range(1,frames+2,3):
    t=(frame-1)/frames;wave=math.sin(t*2*math.pi);x=amplitude*wave*sign
    y=0;roll=0
    if clip=='idle' and not leg:x=.025*wave
    if clip in ['pickup','plant_trap'] and not leg:x=-1.0*math.sin(t*math.pi)
    if clip=='react_slip':x=(-.6 if leg else -1.2)*math.sin(t*math.pi);roll=sign*.4*math.sin(t*math.pi)
    if clip=='react_surprise' and not leg:x=-1.4*math.sin(t*math.pi);roll=sign*.3*math.sin(t*math.pi)
    if clip=='celebrate' and not leg:roll=sign*(.9+.2*wave);x=-.4
    limb.rotation_euler=(x,y,roll);limb.keyframe_insert(data_path='rotation_euler',frame=frame)
   track=limb.animation_data.nla_tracks.new();track.name=clip;strip=track.strips.new(clip,1,action);strip.name=clip
   limb.animation_data.action=None;limb.rotation_euler=(0,0,0)
 for limb in limbs:
  for track in limb.animation_data.nla_tracks:track.mute=True
# Materials stay PBR; soften plastic highlights on skin.
for mat in bpy.data.materials:
 if not mat.use_nodes:continue
 node=mat.node_tree.nodes.get('Principled BSDF')
 if node and mat.name=='Warm peach skin':node.inputs['Roughness'].default_value=.8
scene.frame_set(1)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ROOT,'art/two_storey_game.blend'))
# Enable tracks for export; exporter isolates matching NLA track names.
for obj in bpy.data.objects:
 if obj.animation_data:
  for track in obj.animation_data.nla_tracks:track.mute=False
  obj.animation_data.action=obj.animation_data.nla_tracks[0].strips[0].action
bpy.ops.export_scene.gltf(filepath=os.path.join(ROOT,'assets/models/two_storey.glb'),export_format='GLB',export_animations=True,export_animation_mode='NLA_TRACKS',export_nla_strips=True,export_force_sampling=True,export_frame_range=False,export_cameras=False,export_lights=False)
print('REFINED_CAST_WITH_NINE_CLIPS')
