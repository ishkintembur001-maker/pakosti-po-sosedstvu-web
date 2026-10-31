import bpy, math, random, os
from mathutils import Vector, Matrix
from math import sin, cos, pi
random.seed(18)
OUT=os.path.abspath(os.path.join(os.path.dirname(__file__),'../assets/models'))
os.makedirs(OUT,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)

def lin(v): return v/12.92 if v<.04045 else ((v+.055)/1.055)**2.4
def rgb(h): return tuple(lin(int(h[i:i+2],16)/255) for i in (0,2,4))+(1,)
materials={}
def mat(name,h,rough=.6,metal=0,texture=None):
 m=bpy.data.materials.new(name);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=rgb(h);p.inputs['Roughness'].default_value=rough;p.inputs['Metallic'].default_value=metal
 if texture:
  tex=m.node_tree.nodes.new('ShaderNodeTexImage');tex.image=bpy.data.images.load(os.path.join(os.path.dirname(__file__),'textures',texture));m.node_tree.links.new(tex.outputs['Color'],p.inputs['Base Color'])
 materials[name]=m;return m
wood=mat('Honey oak • grain','956341',.52,texture='oak.png');dark=mat('Walnut • polished edges','493026',.46,texture='walnut.png');trim=mat('Aged champagne brass','a9874f',.32,.65)
wall=mat('Sage damask • woven wallpaper','66816c',.92,texture='wallpaper.png');cream=mat('Warm ivory enamel','c0b69b',.62);red=mat('Oxblood upholstery • woven checks','914940',.85,texture='upholstery.png');rug=mat('Persian wool • ornamental border','953d3c',.98,texture='rug.png')
teal=mat('Petrol knit cotton','216571',.88,texture='hoodie.png');denim=mat('Indigo denim • twill','354660',.92,texture='denim.png');plaid=mat('Burgundy plaid robe','8d3537',.93,texture='plaid.png');shorts=mat('Blue check shorts','425b78',.92,texture='shorts.png');skin=mat('Warm peach skin','dca67e',.7);blush=mat('Warm cheeks','c58069',.8);hair=mat('Chestnut hair','503024',.7);black=mat('Soft charcoal','25282b',.83);white=mat('Warm white','e8e0cd',.65);iris=mat('Hazel irises','624b30',.36);pupil=mat('Deep pupils','111a1b',.27);cap=mat('Carmine canvas','ab4038',.88,texture='cap.png');sole=mat('Rubber sneaker soles','d2c6a8',.85);leaf=mat('Variegated green','355b39',.8);pot=mat('Terracotta pottery','a06b48',.84);tile=mat('Muted jade glazed tile','6e938c',.3,texture='tile.png');water=mat('Bath turquoise','467a83',.24,.1);glass=mat('Midnight glass','263c4a',.21,.25);paper=mat('Book paper','c5b18b',.9);purple=mat('Violet paint','794391',.24);yellow=mat('Banana ochre','e2b648',.5)

def empty(name,parent=None,loc=(0,0,0)):
 o=bpy.data.objects.new(name,None);bpy.context.collection.objects.link(o);o.parent=parent;o.location=loc;return o
root=empty('ApartmentCast');env=empty('ApartmentEnvironment',root)

def finish(o,name,m,parent):
 o.name=name;o.data.materials.clear();o.data.materials.append(m);o.parent=parent
 for p in o.data.polygons:p.use_smooth=True
 return o

def cube(name,loc,size,m,parent=env,bevel=.04):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.scale=size;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 if bevel:
  b=o.modifiers.new('Soft manufactured edge','BEVEL');b.width=bevel;b.segments=3
  bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=b.name)
  b=o.modifiers.new('Weighted corner normals','WEIGHTED_NORMAL');b.keep_sharp=True;bpy.ops.object.modifier_apply(modifier=b.name)
 finish(o,name,m,parent)
 if m in [wood,dark,wall,teal,denim,red,plaid,shorts,cap,tile]:
  scale=1.5 if m==wall else (2.5 if m in [teal,denim,red,plaid,shorts,cap] else .8)
  uv=o.data.uv_layers.active
  for poly in o.data.polygons:
   for li in poly.loop_indices:
    co=o.data.vertices[o.data.loops[li].vertex_index].co+o.location
    n=poly.normal
    if abs(n.z)>.65:u,v=co.x,co.y
    elif abs(n.y)>.65:u,v=co.x,co.z
    else:u,v=co.y,co.z
    uv.data[li].uv=(u*scale,v*scale)
 return o

def uvmesh(name,verts,faces,m,parent):
 me=bpy.data.meshes.new(name);me.from_pydata(verts,[],faces);me.update();o=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(o);finish(o,name,m,parent)
 uv=me.uv_layers.new()
 for poly in me.polygons:
  for li in poly.loop_indices:
   co=me.vertices[me.loops[li].vertex_index].co
   # World-space planar mapping based on dominant face normal, with cloth scale.
   n=poly.normal
   if abs(n.z)>.65:u,v=co.x,co.y
   elif abs(n.y)>.65:u,v=co.x,co.z
   else:u,v=co.y,co.z
   uv.data[li].uv=(u*.6,v*.6)
 return o

def oval(name,loc,scale,m,parent=env,seg=24,rings=14):
 vs=[];fs=[]
 for j in range(rings+1):
  a=pi*j/rings
  for i in range(seg):
   t=2*pi*i/seg;vs.append((loc[0]+scale[0]*sin(a)*cos(t),loc[1]+scale[1]*sin(a)*sin(t),loc[2]+scale[2]*cos(a)))
 for j in range(rings):
  for i in range(seg):a=j*seg+i;b=j*seg+(i+1)%seg;fs.append((a,b,b+seg,a+seg))
 return uvmesh(name,vs,[tuple(reversed(f)) for f in fs],m,parent)

def tube(name,points,radii,m,parent=env,sides=10):
 vs=[];fs=[]
 for i,p in enumerate(points):
  p=Vector(p);t=Vector(points[min(i+1,len(points)-1)])-Vector(points[max(0,i-1)]);t.normalize();u=t.cross(Vector((0,0,1)))
  if u.length<.01:u=t.cross(Vector((0,1,0)))
  u.normalize();v=t.cross(u).normalized()
  for k in range(sides):q=p+radii[i]*(u*cos(k*2*pi/sides)+v*sin(k*2*pi/sides));vs.append(q)
 for i in range(len(points)-1):
  for k in range(sides):a=i*sides+k;b=i*sides+(k+1)%sides;fs.append((a,b,b+sides,a+sides))
 fs.append(tuple(range(sides-1,-1,-1)));fs.append(tuple((len(points)-1)*sides+k for k in range(sides)))
 return uvmesh(name,vs,fs,m,parent)

def curve(name,points,r,m,parent=env):return tube(name,points,[r]*len(points),m,parent)

def lathe(name,loc,profile,m,parent=env,n=32):
 vs=[];fs=[]
 for z,r in profile:
  for i in range(n):a=i*2*pi/n;vs.append((loc[0]+r*cos(a),loc[1]+r*sin(a),loc[2]+z))
 for j in range(len(profile)-1):
  for i in range(n):a=j*n+i;b=j*n+(i+1)%n;fs.append((a,b,b+n,a+n))
 return uvmesh(name,vs,fs,m,parent)

def torso(name,profile,m,parent,n=32):
 vs=[];fs=[]
 for z,rx,ry,y in profile:
  for i in range(n):a=2*pi*i/n;vs.append((rx*cos(a),y+ry*sin(a),z))
 for j in range(len(profile)-1):
  for i in range(n):a=j*n+i;b=j*n+(i+1)%n;fs.append((a,b,b+n,a+n))
 return uvmesh(name,vs,fs,m,parent)

# Sculpted cast. Blender -Y is the face direction; glTF maps it to Godot +Z.
def person(enemy=False):
 p=empty('NeighborCharacter' if enemy else 'TricksterCharacter',root)
 s=1.13 if enemy else 1
 # Character height 2.05 / 2.35 metres, designed to remain legible from play camera.
 z=1.69 if enemy else 1.58
 h=.43 if enemy else .40;w=.39 if enemy else .34
 head=torso('Sculpted cheekbones and jaw',[(z-h,.025,.035,0),(z-h*.85,w*.54,.21,-.015),(z-h*.55,w*.87,.28,-.025),(z-h*.1,w,.31,0),(z+h*.4,w*.96,.29,.012),(z+h*.8,w*.7,.22,.02),(z+h,.025,.03,.03)],skin,p,40)
 sub=head.modifiers.new('Sculpt surface','SUBSURF');sub.levels=1;bpy.context.view_layer.objects.active=head;bpy.ops.object.modifier_apply(modifier=sub.name)
 for side in [-1,1]:
  oval('Ear helix', (side*w*1.02,0,z-.015),(.09,.065,.14),skin,p)
  oval('Ear hollow',(side*w*1.1,-.043,z-.015),(.044,.025,.078),blush,p)
  ex=side*(.154 if enemy else .132)
  oval('Eyeball',(ex,-.265,z+.06),(.125,.072,.113 if not enemy else .095),white,p)
  oval('Hazel iris',(ex+(.018 if not enemy else -side*.015),-.331,z+.055),(.047,.012,.059),iris,p)
  oval('Pupil',(ex+.014,-.342,z+.055),(.024,.008,.038),pupil,p)
  oval('Eye catchlight',(ex+.001,-.351,z+.081),(.012,.005,.014),white,p,12,8)
  curve('Lower eyelid',[(ex-.105+i*.021,-.31,z+.01-.025*sin(i*pi/10)) for i in range(11)],.012,skin,p)
  # Inward angled brow for neighbor, jaunty raised brow for trickster.
  curve('Expressive brow',[(ex-.113+i*.022,-.309,z+.19+(side*(-.045+i*.009) if enemy else .035*sin(i*pi/10))) for i in range(11)],.029 if enemy else .025,hair,p)
  oval('Cheek volume',(side*.22,-.232,z-.085),(.115,.069,.089),skin,p)
  if not enemy:
   for k in range(6):oval('Freckle',(side*(.18+(k%3)*.025),-.3+(k%3)*.009,z-.07+(k//3)*.025),(.005,.003,.006),hair,p,8,6)
 oval('Nose bridge',(0,-.285,z-.005),(.074,.091,.115),skin,p)
 oval('Rounded nose tip',(0,-.37,z-.05),(.11 if enemy else .078,.08,.072),blush if enemy else skin,p)
 if enemy:
  for side in [-1,1]:
   tube('Swept moustache',[(0,-.33,z-.155),(side*.09,-.346,z-.145),(side*.18,-.31,z-.16),(side*.25,-.285,z-.12)],[.045,.055,.038,.005],hair,p,12)
  curve('Frowning lip',[(-.14+i*.028,-.29,z-.25+.045*sin(i*pi/10)) for i in range(11)],.023,blush,p)
  # Male pattern hairline and a sculpted quiff.
  for side in [-1,1]:oval('Side hair',(side*.32,.065,z+.13),(.08,.21,.18),hair,p)
  for k in range(5):tube('Receding quiff',[(.07-k*.03,.04,z+.36),(.08-k*.03,.07,z+.5),(.035-k*.02,-.035,z+.56)],[.07,.065,.003],hair,p,10)
 else:
  curve('Smile crease',[(-.14+i*.028,-.278,z-.18-.048*sin(i*pi/10)) for i in range(11)],.022,hair,p)
  curve('Little smile teeth',[(-.11+i*.022,-.295,z-.184-.034*sin(i*pi/10)) for i in range(11)],.012,white,p)
  # Backward baseball cap crown, inset side panels, seam and bill.
  torso('Cap crown',[(z+.22,.345,.29,.025),(z+.35,.31,.26,.03),(z+.44,.23,.20,.035),(z+.49,.015,.02,.04)],cap,p)
  for side in [-1,1]:curve('Cap stitched seams',[(side*.27,.03,z+.25),(side*.23,.045,z+.37),(side*.10,.045,z+.47)],.009,white,p)
  bill=oval('Backward curved cap bill',(0,.36,z+.255),(.35,.26,.035),cap,p)
  oval('Cap button',(0,.03,z+.492),(.035,.035,.019),cap,p)
  for k in range(10):
   x=-.28+k*.058
   tube('Sculpted swept hair lock',[(x,.015,z+.29),(x*1.05,-.18,z+.33),(x+.08,-.29,z+.21),(x+.10,-.29,z+.13)],[.075,.085,.05,.003],hair,p,10)
 # Neck and body, hand made lofts with silhouette compression and shoulder volume.
 oval('Neck',(0,0,1.23 if not enemy else 1.3),(.15,.15,.18),skin,p)
 if enemy:
  torso('Cream undershirt',[(.57,.23,.23,-.02),(.66,.43,.32,-.035),(.91,.51,.38,-.065),(1.15,.48,.30,-.035),(1.31,.32,.21,0),(1.34,.16,.15,0)],cream,p)
  # Robe shell open at chest, separate tailored panels.
  for side in [-1,1]:
   oval('Dressing gown side',(side*.30,.055,.96),(.27,.32,.40),plaid,p)
   curve('Robe lapel',[(side*.20,-.16,1.3),(side*.29,-.28,1.11),(side*.35,-.38,.80),(side*.33,-.3,.60)],.045,red,p)
  curve('Robe belt',[(-.43,-.18,.7),(-.22,-.36,.69),(0,-.43,.68),(.23,-.36,.69),(.43,-.18,.7)],.034,red,p)
  tube('Hanging belt',[(.10,-.43,.69),(.15,-.45,.55),(.12,-.44,.39)],[.035,.031,.015],red,p)
 else:
  torso('Tailored hoodie',[(.59,.24,.16,0),(.65,.29,.21,0),(.80,.31,.22,-.005),(1.05,.33,.23,0),(1.22,.29,.20,.01),(1.28,.15,.13,0)],teal,p)
  oval('Folded hood',(0,.14,1.23),(.26,.18,.17),teal,p)
  cube('Kangaroo pocket',(0,-.218,.79),(.36,.045,.17),teal,p,.045)
  for side in [-1,1]:
   curve('Hood drawstring',[(side*.09,-.18,1.24),(side*.11,-.235,1.11),(side*.10,-.24,1.02)],.012,white,p)
   curve('Pocket seam',[(side*.17,-.247,.88),(side*.19,-.25,.82),(side*.12,-.25,.72)],.007,cream,p)
  oval('Canvas rucksack',(0,.255,.96),(.25,.13,.29),black,p)
  cube('Rucksack pocket',(0,.377,.84),(.32,.055,.16),black,p,.035)
  for side in [-1,1]:curve('Backpack strap',[(side*.23,.27,.76),(side*.25,.03,1.23),(side*.18,-.18,1.19)],.025,black,p)
 # Articulated limbs: pivots are at shoulders and hips, never ankle centres.
 for side,label in [(-1,'L'),(1,'R')]:
  leg=empty('Legs_'+label,p,(side*(.245 if enemy else .145),0,.64 if enemy else .62))
  if enemy:
   torso('Checkered short leg',[(-.25,.18,.19,0),(-.05,.20,.22,0),(.04,.19,.21,0)],shorts,leg,24)
   oval('Knee',(0,-.012,-.29),(.123,.13,.15),skin,leg)
   tube('Calf',[(0,0,-.27),(0,0,-.40),(0,-.015,-.51)],[.12,.09,.085],skin,leg)
  else:
   tube('Denim trouser leg',[(0,0,0),(0,-.012,-.20),(0,.015,-.38),(0,-.015,-.48)],[.126,.115,.105,.09],denim,leg,16)
   for f in range(3):curve('Denim knee fold',[(-.08,-.09,-.22-f*.035),(0,-.12,-.23-f*.035),(.08,-.09,-.215-f*.035)],.008,denim,leg)
  oval('Moulded sneaker sole',(0,-.075,-.54 if not enemy else -.56),(.15 if not enemy else .18,.25,.065),sole,leg)
  oval('Canvas sneaker',(0,-.06,-.49 if not enemy else -.51),(.14 if not enemy else .17,.23,.10),cap if not enemy else plaid,leg)
  oval('Rubber toe cap',(0,-.235,-.49 if not enemy else -.51),(.125 if not enemy else .15,.075,.063),white,leg)
  for j in range(4):curve('Crossed cotton shoelace',[(-.07,-.16+j*.034,-.411),(.07,-.14+j*.034,-.411)],.008,white,leg)
  arm=empty('Arm_'+label,p,(side*(.47 if enemy else .32),0,1.20))
  tube('Fitted curved sleeve',[(0,0,0),(side*.075,-.015,-.15),(side*.10,-.07,-.30)],[.19 if enemy else .135,.16 if enemy else .12,.13 if enemy else .10],plaid if enemy else teal,arm,16)
  tube('Forearm',[(side*.10,-.07,-.29),(side*.11,-.11,-.40),(side*.10,-.14,-.47)],[.12 if enemy else .088,.09,.08],skin,arm,16)
  oval('Hand palm',(side*.10,-.14,-.5),(.105,.067,.11),skin,arm)
  for j in range(4):
   x=side*.10-.069+j*.044
   tube('Individual curled finger',[(x,-.14,-.53),(x,-.17,-.60),(x,-.20,-.61)],[.023,.021,.012],skin,arm,8)
  tube('Curved thumb',[(side*.015,-.13,-.48),(side*-.025,-.19,-.51),(side*.005,-.22,-.54)],[.036,.029,.016],skin,arm,8)
 # Author real animation clips, keyed on these limb pivots.
 limbs=[c for c in p.children if c.type=='EMPTY' and (c.name.startswith('Legs_') or c.name.startswith('Arm_'))]
 for o in limbs:
  sign=1 if o.name.startswith(('Legs_L','Arm_R')) else -1
  for frame,a in [(1,0),(7,.44*sign),(13,0),(19,-.44*sign),(25,0)]:
   o.rotation_euler.x=a;o.keyframe_insert(data_path='rotation_euler',frame=frame,group='Walk cycle')
  o.rotation_euler.x=0
 return p
hero=person(False);neighbor=person(True)
# At-rest cast lives at origin and is hidden by the game; clones are animated in Godot.

# Architectural shell, raised slab, inset plank floor, patterned papers and woodwork.
cube('Foundation plinth',(0,0,-.19),(16.12,9.5,.35),dark,bevel=.13)
cube('Brass foundation reveal',(0,0,-.08),(16.0,9.38,.04),trim,bevel=.01)
for ix in range(16):
 for iy in range(6):
  x=-7.5+ix; y=-4.1+iy*1.48
  if y>0 and x>0:continue
  o=cube('Individual oak floorboard',(x,y,-.005),( .985,1.465,.09),wood,bevel=.008)
  # Small deterministic variation avoids a repeating flat rectangle.
  for uv in o.data.uv_layers.active.data:uv.uv.x+=random.random()*.1
cube('Bathroom ceramic floor',(3.94,2.31,.005),(7.75,4.50,.10),tile,bevel=.015)
# Rear and west walls retain enough height for windows; foreground is cut away.
def wall_segment(name,x,y,w,d,h,material=wall):
 cube(name,(x,y,h/2),(w,d,h),material,bevel=.022)
 cube('Skirting',(x,y,.12),(w+.04,d+.04,.22),dark,bevel=.015)
 cube('Skirting highlight',(x,y,.24),(w+.055,d+.055,.025),trim,bevel=.005)
 cube('Crown moulding',(x,y,h+.025),(w+.06,d+.06,.11),cream,bevel=.025)
wall_segment('Damask rear wall',0,-4.64,15.94,.18,2.45)
wall_segment('Damask west wall',-7.94,0,.18,9.3,1.75)
wall_segment('Cutaway front trim',0,4.64,15.95,.15,.26,dark)
wall_segment('Cutaway east trim',7.94,0,.15,9.3,.30,dark)
for x in [-4.15,4.15]:wall_segment('Central wall cutaway',x,0,6.6,.16,.62)
for y in [-2.7,2.7]:wall_segment('Hall wall cutaway',0,y,.16,3.5,.66)
# Raised panel wainscot on rear wall.
for x in [i*.70-7.35 for i in range(22)]:
 cube('Wainscot inset',(x,-4.52,.46),(.61,.04,.63),dark,bevel=.02)
 cube('Wainscot inner panel',(x,-4.48,.46),(.49,.025,.49),wood,bevel=.015)
cube('Dado rail',(0,-4.46,.84),(15.8,.09,.09),trim,bevel=.02)
for x in [-5.5,3.9]:
 cube('Window oak surround',(x,-4.49,1.67),(1.64,.15,1.48),dark,bevel=.06)
 cube('Window blue sky',(x,-4.39,1.67),(1.43,.025,1.27),glass,bevel=.01)
 for dx in [-.71,0,.71]:cube('Window mullion',(x+dx,-4.34,1.67),(.045,.07,1.31),cream,bevel=.008)
 cube('Window transom',(x,-4.34,1.65),(1.44,.07,.045),cream,bevel=.008)
 cube('Window sill',(x,-4.25,.94),(1.83,.38,.12),cream,bevel=.03)
 for side in [-1,1]:
  for k in range(6):
   oval('Curtain pleat',(x+side*(.84+k*.036),-4.31,1.69),(.045,.07,.72),red,seg=12,rings=8)
 curve('Curtain rod',[(x-1.14,-4.29,2.46),(x+1.14,-4.29,2.46)],.025,trim)
# Rugs with woven border textures.
for x,y,sx,sy in [(-4.6,-2.05,4.4,2.9),(4,-1.9,4.6,3.1),(0,0,1.45,1.65)]:
 o=cube('Persian carpet',(x,y,.07),(sx,sy,.045),rug,bevel=.03)
 # Assign full rug texture to horizontal face.
 for poly in o.data.polygons:
  if poly.normal.z>.8:
   for li in poly.loop_indices:
    co=o.data.vertices[o.data.loops[li].vertex_index].co;o.data.uv_layers.active.data[li].uv=(co.x/sx+.5,co.y/sy+.5)
 for i in range(28):
  for edge in [-1,1]:curve('Carpet tassel',[(x-sx/2+i*sx/28,y+edge*sy/2,.08),(x-sx/2+i*sx/28,y+edge*(sy/2+.065),.075)],.007,cream)
# Sofa: carved feet, rounded cushions, piping and tuft buttons.
for x in [-6.4,-4.4]:
 for y in [-3.55,-2.91]:lathe('Turned sofa foot',(x,y,0),[(0,.065),(.08,.07),(.13,.04),(.20,.06)],dark,n=16)
cube('Sofa upholstered base',(-5.4,-3.28,.35),(2.65,.92,.45),red,bevel=.16)
cube('Sofa upholstered back',(-5.4,-3.68,.78),(2.65,.28,.92),red,bevel=.13)
for x in [-6.64,-4.16]:cube('Sofa rolled arm',(x,-3.25,.65),(.32,.98,.66),red,bevel=.15)
for i in range(3):
 x=-6.18+i*.78;cube('Separate seat cushion',(x,-3.22,.61),(.74,.72,.20),red,bevel=.095)
 curve('Seat piping',[(x-.32,-3.56,.68),(x+.32,-3.56,.68),(x+.34,-2.91,.68),(x-.34,-2.91,.68),(x-.32,-3.56,.68)],.008,cream)
 for j in range(2):oval('Upholstery tuft',(x,-3.505,.85+j*.24),(.024,.015,.024),trim)
for x,m in [(-6.05,teal),(-4.7,cream)]:
 o=cube('Soft accent pillow',(x,-3.45,.88),(.50,.18,.47),m,bevel=.15);o.rotation_euler.y=.18
# Tables, legs and books.
def table(x,y,w,d,h):
 cube('Bevelled table top',(x,y,h),(w,d,.12),wood,bevel=.065)
 for sx in [-1,1]:
  for sy in [-1,1]:
   tube('Tapered table leg',[(x+sx*(w/2-.15),y+sy*(d/2-.12),h-.04),(x+sx*(w/2-.19),y+sy*(d/2-.15),.12)],[.06,.035],dark,sides=10)
table(-4.4,-1.85,1.5,.78,.48);table(-3.15,2.1,1.45,1.05,.71)
for x,y,z in [(-4.7,-1.85,.58),(-3.3,2.1,.81)]:
 cube('Book cover',(x,y,z),(.38,.25,.035),plaid,bevel=.008);cube('Book pages',(x,y,z+.035),(.35,.23,.035),paper,bevel=.005)
 lathe('Ceramic mug',(x+.4,y,z),[(0,.08),(.02,.085),(.18,.075),(.19,.08),(.18,.06),(.04,.055)],cream,n=24)
 curve('Mug handle',[(x+.47,y,z+.04),(x+.55,y,z+.04),(x+.55,y,z+.15),(x+.47,y,z+.15)],.015,cream)
for x in [-2.05,-4.25]:
 cube('Chair seat',(x,2.1,.46),(.49,.51,.10),wood,bevel=.045)
 for dx in [-.18,.18]:
  for dy in [-.18,.18]:curve('Chair leg',[(x+dx,2.1+dy,.43),(x+dx*1.15,2.1+dy*1.15,.05)],.025,dark)
 cube('Chair curved back',(x,2.33,.80),(.46,.07,.53),wood,bevel=.055)
 for dx in [-.12,0,.12]:cube('Chair back inset',(x+dx,2.28,.81),(.035,.025,.33),dark,bevel=.008)
# Kitchen cabinets, door framing, countertop, sink and tap.
cube('Cabinet carcass',(-6.35,2.85,.42),(.83,2.4,.84),dark)
cube('Stone countertop',(-6.35,2.85,.90),(.96,2.54,.13),cream,bevel=.035)
for y in [1.98,2.57,3.16,3.75]:
 cube('Kitchen framed door',(-5.91,y,.46),(.07,.54,.68),teal,bevel=.025)
 cube('Kitchen door recess',(-5.86,y,.45),(.025,.40,.47),teal,bevel=.015)
 curve('Kitchen brass handle',[(-5.82,y-.08,.69),(-5.82,y+.08,.69)],.015,trim)
lathe('Inset porcelain sink',(-6.35,2.28,.96),[(0,.26),(-.12,.18),(-.13,.15),(-.08,.13),(.012,.28),(.025,.30),(.005,.31)],cream)
curve('Bent brass kitchen tap',[(-6.62,2.28,.96),(-6.62,2.28,1.20),(-6.60,2.28,1.27),(-6.49,2.28,1.27),(-6.43,2.28,1.17)],.022,trim)
cube('Retro cream refrigerator',(-7,1,.85),(.72,.78,1.70),cream,bevel=.09)
for z,h in [(.65,1.05),(1.42,.40)]:
 cube('Fridge door',(-6.6,1,z),(.07,.68,h),cream,bevel=.045)
 curve('Fridge chrome handle',[(-6.54,.78,z-.12),(-6.54,.78,z+.12)],.018,trim)
for z in [.94,1.08]:cube('Fridge magnet',(-6.54,1.15,z),(.025,.09,.07),cap,bevel=.015)
cube('Range oven',(-4.6,4.08,.41),(1.15,.65,.82),cream,bevel=.055)
cube('Oven dark glass',(-4.6,3.73,.40),(.88,.03,.43),glass,bevel=.025)
curve('Oven handle',[(-4.99,3.68,.66),(-4.21,3.68,.66)],.022,trim)
for dx in [-.28,.28]:
 for dy in [-.15,.15]:lathe('Stove burner',(-4.6+dx,4.08+dy,.84),[(0,.115),(.016,.12),(.018,.09),(.01,.08)],black,n=20)
for x in [-4.98,-4.74,-4.5,-4.26]:oval('Oven dial',(x,3.72,.75),(.037,.025,.037),black)
lathe('Copper saucepan',(-4.87,4.22,.87),[(0,.10),(.14,.14),(.16,.145),(.16,.125),(.03,.09)],pot,n=24)
curve('Saucepan handle',[(-4.86,4.32,.96),(-4.86,4.63,.98)],.025,dark)
# Open wall shelf with jars, ceramics and hanging pans.
cube('Kitchen open shelf',(-6.9,3.0,1.55),(.37,2.5,.09),wood)
for i in range(7):
 y=2+i*.29;lathe('Spice jar',(-6.85,y,1.60),[(0,.064),(.15,.064),(.17,.05),(.19,.05)],pot if i%2 else cream,n=16);lathe('Spice jar lid',(-6.85,y,1.79),[(0,.057),(.025,.057)],trim,n=16)
# Bed with rounded quilt folds, seams, pillows and turned posts.
cube('Bed carved frame',(4.8,-3,.30),(2.65,2.07,.36),dark,bevel=.07)
cube('Bed headboard',(4.8,-3.97,.88),(2.72,.14,1.37),wood,bevel=.10)
for x in [3.48,6.12]:
 lathe('Bed turned post',(x,-3.97,.14),[(0,.06),(1.35,.065),(1.4,.10),(1.49,.02)],dark,n=20)
cube('Soft mattress',(4.8,-3,.55),(2.46,1.91,.28),cream,bevel=.13)
cube('Quilted teal blanket',(4.8,-2.62,.72),(2.44,1.13,.15),teal,bevel=.10)
for i in range(12):
 x=3.65+i*.21;curve('Quilt stitch',[(x,-3.1,.79),(x+.013,-2.68,.80),(x,-2.1,.78)],.006,cream)
for x in [4.12,5.48]:
 o=cube('Pillow cotton',(x,-3.57,.79),(.79,.52,.23),cream,bevel=.13);o.rotation_euler.z=.07 if x<4.8 else -.06
for x,y in [(6.72,-3.4),(-3.77,-3.6)]:
 cube('Nightstand',(x,y,.37),(.58,.61,.72),wood,bevel=.035)
 for z in [.30,.59]:
  cube('Drawer inset',(x,y+.32,z),(.46,.04,.21),dark,bevel=.02);oval('Drawer brass pull',(x,y+.355,z),(.046,.025,.026),trim)
 lathe('Lamp brass base',(x,y,.75),[(0,.16),(.04,.17),(.07,.08),(.34,.025),(.39,.07)],trim)
 lathe('Pleated lampshade',(x,y,1.1),[(0,.26),(.02,.27),(.40,.15),(.42,.15)],cream,n=32)
# Tall bookcase sits against rear wall, away from gameplay corridors.
cube('Bookcase backing',(-2.6,-4.35,1.15),(1.45,.10,2.17),dark)
for x in [-3.32,-1.88]:cube('Bookcase stile',(x,-4.18,1.15),(.10,.47,2.22),wood)
for z in [.12,.60,1.08,1.56,2.22]:cube('Bookcase shelf',(-2.6,-4.12,z),(1.47,.55,.07),wood)
for row in range(4):
 for i in range(9):
  x=-3.17+i*.135;h=random.uniform(.22,.38);m=[red,teal,denim,cream][(i+row)%4];cube('Cloth book spine',(x,-4.03,.17+row*.48+h/2),(.10,.26,h),m,bevel=.008)
  for dz in [.04,h-.04]:cube('Book gilded band',(x,-3.89,.17+row*.48+dz),(.085,.009,.009),trim,bevel=.002)
# Portrait frames, pictures and clock.
for x in [-.94,1.3,6.75]:
 cube('Portrait carved frame',(x,-4.47,1.57),(.73,.13,.94),dark,bevel=.035)
 cube('Portrait gold inset',(x,-4.38,1.57),(.63,.035,.84),trim,bevel=.015)
 cube('Portrait painted ground',(x,-4.35,1.57),(.53,.02,.74),teal,bevel=.005)
 oval('Painted portrait head',(x,-4.32,1.65),(.12,.015,.15),skin,seg=16,rings=10)
 oval('Painted portrait shoulders',(x,-4.32,1.36),(.21,.015,.14),red,seg=16,rings=10)
# Bath, rolled rim, taps, towel rail, mirror.
cube('Bath pedestal',(5.1,3.45,.22),(2.48,1.34,.43),cream,bevel=.19)
cube('Bath turquoise water',(5.1,3.45,.45),(2.17,1.03,.04),water,bevel=.17)
for x in [-1,1]:
 for y in [-1,1]:oval('Bath claw foot',(5.1+x*.97,3.45+y*.40,.10),(.12,.13,.10),trim)
for x in [-1,1]:cube('Bath rolled long rim',(5.1,3.45+x*.61,.50),(2.26,.13,.14),cream,bevel=.06)
for x in [-1,1]:cube('Bath rolled short rim',(5.1+x*1.17,3.45,.50),(.14,1.20,.14),cream,bevel=.06)
curve('Bath gooseneck tap',[(6.12,3.94,.49),(6.12,3.94,.79),(6.0,3.94,.85),(5.9,3.94,.75)],.024,trim)
cube('Washstand',(6.85,1.28,.39),(.58,.95,.78),teal,bevel=.045)
lathe('Wash basin',(6.85,1.28,.81),[(0,.19),(.08,.30),(.13,.32),(.15,.30),(.12,.27),(.04,.17)],cream)
curve('Towel rail',[(7.62,2,.95),(7.62,3.1,.95)],.022,trim)
cube('Folded cotton towel',(7.60,2.5,.68),(.06,.55,.52),cream,bevel=.035)
# Closets retain EXACT original interaction and collision footprints.
for x,y in [(-6.5,-1.25),(1.5,3.35)]:
 cube('Wardrobe carcass',(x,y,.82),(.90,.80,1.64),dark,bevel=.055)
 cube('Wardrobe cornice',(x,y,1.66),(1.0,.90,.12),wood,bevel=.035)
 for dx in [-.22,.22]:
  cube('Raised panel wardrobe door',(x+dx,y+.43,.85),(.41,.055,1.43),wood,bevel=.025)
  for z,h in [(.50,.51),(1.18,.49)]:cube('Wardrobe recessed panel',(x+dx,y+.468,z),(.30,.025,h),dark,bevel=.02)
  oval('Wardrobe brass knob',(x+dx*.27,y+.50,.88),(.028,.026,.028),trim)
# Plants with individual curved lanceolate leaves and stems.
for x,y in [(-5.15,-1),(6.8,-1.3),(-6.8,3.9),(.65,-3.55),(-.9,-4.2)]:
 lathe('Glazed terracotta pot',(x,y,0),[(0,.15),(.06,.17),(.39,.25),(.43,.25),(.45,.22),(.42,.20)],pot,n=24)
 for i in range(9):
  a=i*2.4;h=.68+(i%3)*.13;r=.35
  curve('Plant stem',[(x,y,.39),(x+cos(a)*.12,y+sin(a)*.12,h-.1),(x+cos(a)*r,y+sin(a)*r,h)],.012,leaf)
  o=oval('Lanceolate leaf',(x+cos(a)*.29,y+sin(a)*.29,h),(.085,.24,.026),leaf,seg=12,rings=8);o.data.transform(Matrix.Translation(Vector((-x-cos(a)*.29,-y-sin(a)*.29,-h))));o.location=(x+cos(a)*.29,y+sin(a)*.29,h);o.rotation_euler.z=-a
# Extra visual variants follow gameplay changes, enabled by level index in Godot.
for lev in [1,2,3]:
 group=empty('EpisodeDetail%d'%lev,env)
 if lev==1:
  cube('Extra bookcase',(-1.15,2.95,.65),(.40,1.28,1.30),dark,group)
 elif lev==2:
  cube('Suitcase',(5.85,-1.05,.40),(.60,.44,.80),red,group,.08)
  for dx in [-.18,.18]:cube('Leather luggage strap',(5.85+dx,-.81,.40),(.055,.03,.75),dark,group,.012)
 else:
  for h in [0,.42]:cube('Cardboard storage box',(-2,-2.82,h+.21),(.8,.78,.41),paper,group,.03)
# Sculpted prank props replace the old debug primitives.
props = empty('PrankProps', root)
for k in range(4):
 group=empty('Prop%d'%k, props)
 if k==0:
  for a in [0,pi/2,pi,pi*1.5]:
   pts=[]
   for j in range(9):
    t=j/8;r=.06+.36*t
    pts.append((cos(a)*r,sin(a)*r,.26*(1-t)**2+.035))
   tube('Curled banana peel',pts,[.065*(1-j/9) for j in range(9)],yellow,group,12)
  tube('Banana stem',[(0,0,.12),(0,0,.35),(.035,0,.40)],[.07,.047,.028],yellow,group,12)
 elif k==1:
  lathe('Metal paint bucket',(0,0,0),[(0,.19),(.03,.21),(.38,.235),(.41,.25),(.44,.25),(.44,.22),(.39,.21)],trim,group)
  lathe('Purple paint surface',(0,0,.39),[(0,.005),(0,.22)],purple,group)
  curve('Wire bucket handle',[(cos(a)*.28,0,.26+sin(a)*.44) for a in [j*pi/16 for j in range(17)]],.014,black,group)
  for a in [0,1.2,2.3]:
   tube('Paint drip',[(.23*cos(a),.23*sin(a),.42),(.235*cos(a),.235*sin(a),.27),(.23*cos(a),.23*sin(a),.24)],[.035,.028,.006],purple,group)
  tube('Paintbrush handle',[(.1,0,.36),(.24,.03,.77)],[.025,.018],wood,group)
  cube('Paintbrush bristles',(.11,0,.40),(.09,.06,.13),purple,group,.015)
 elif k==2:
  cube('Rounded blue soap',(0,0,.12),(.42,.28,.18),water,group,.08)
  for j in range(6):
   oval('Soap foam bubble',(.15*cos(j*2),.12*sin(j*2),.16+(j%3)*.07),(.045,.045,.045),white,group,12,8)
 else:
  lathe('Confetti popper',(0,0,0),[(0,.11),(.30,.17),(.34,.18)],teal,group,n=24)
  for j in range(9):
   a=j*2.4;curve('Paper streamer',[(0,0,.31),(.1*cos(a),.1*sin(a),.45),(.22*cos(a),.22*sin(a),.55)],.014,[cap,yellow,purple][j%3],group)
# Merge by material inside each articulated group: bounded draw calls, no object soup.
def merge_group(group):
 for child in list(group.children):
  if child.type=='EMPTY':merge_group(child)
 meshes=[o for o in group.children if o.type=='MESH']
 by={}
 for o in meshes:by.setdefault(o.data.materials[0].name,[]).append(o)
 for name,objs in by.items():
  bpy.ops.object.select_all(action='DESELECT')
  for o in objs:o.select_set(True)
  bpy.context.view_layer.objects.active=objs[0]
  if len(objs)>1:bpy.ops.object.join()
  o=bpy.context.object;o.name=group.name+'_'+name
merge_group(root)
# Bake the coordinate reflection to vertices, avoiding mixed-sign node scale.
import bmesh
reflection=Matrix.Diagonal((1,-1,1,1))
for o in list(env.children_recursive):
 if o.type=='MESH':
  transform=reflection @ o.matrix_world.copy()
  o.data.transform(transform)
  o.matrix_world=Matrix.Identity(4)
  bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.reverse_faces(bm,faces=list(bm.faces));bm.to_mesh(o.data);bm.free()
# Baked vertex occlusion gives contact depth on the Web compatibility renderer.
from mathutils.bvhtree import BVHTree
vs=[];fs=[]
for o in env.children_recursive:
 if o.type=='MESH':
  offset=len(vs);vs.extend([o.matrix_world @ v.co for v in o.data.vertices]);fs.extend([tuple(offset+i for i in p.vertices) for p in o.data.polygons])
bvh=BVHTree.FromPolygons(vs,fs,all_triangles=False)
for o in env.children_recursive:
 if o.type!='MESH':continue
 attr=o.data.color_attributes.new(name='Col',type='BYTE_COLOR',domain='POINT')
 normal_matrix=o.matrix_world.to_3x3().inverted().transposed()
 for v in o.data.vertices:
  pos=o.matrix_world@v.co;n=(normal_matrix@v.normal).normalized()
  tangent=n.cross(Vector((0,0,1)))
  if tangent.length<.01:tangent=n.cross(Vector((0,1,0)))
  tangent.normalize();bitangent=n.cross(tangent)
  occ=0
  for j in range(5):
   a=j*2.39996;direction=(n*.65+tangent*cos(a)*.76+bitangent*sin(a)*.76).normalized()
   hit,nn,idx,dist=bvh.ray_cast(pos+n*.025,direction,1.1)
   if hit is not None:occ+=(1-dist/1.1)
  shade=1-.48*occ/5
  attr.data[v.index].color=(shade,shade,shade,1)
for o in bpy.data.objects:
 if o.type=='MESH' and not o.data.color_attributes.get('Col'):
  col=o.data.color_attributes.new(name='Col',type='BYTE_COLOR',domain='POINT')
  for v in col.data:v.color=(1,1,1,1)
# glTF recognizes the vertex-color multiply pattern as COLOR_0.
for m in materials.values():
 nt=m.node_tree;p=nt.nodes.get('Principled BSDF');c=nt.nodes.new('ShaderNodeVertexColor');c.layer_name='Col';mix=nt.nodes.new('ShaderNodeMixRGB');mix.blend_type='MULTIPLY';mix.inputs[0].default_value=1
 links=list(p.inputs['Base Color'].links)
 if links:nt.links.new(links[0].from_socket,mix.inputs[1])
 else:mix.inputs[1].default_value=p.inputs['Base Color'].default_value
 nt.links.new(c.outputs['Color'],mix.inputs[2]);nt.links.new(mix.outputs[0],p.inputs['Base Color'])
bpy.context.scene.frame_set(1)
bpy.ops.wm.save_as_mainfile(filepath=os.path.abspath(os.path.join(os.path.dirname(__file__),'apartment_cast.blend')))
bpy.ops.export_scene.gltf(filepath=os.path.join(OUT,'apartment_cast.glb'),export_format='GLB',export_yup=True,export_animations=True,export_frame_range=False,export_animation_mode='ACTIONS',export_materials='EXPORT',export_image_format='AUTO',export_all_vertex_colors=True)
print('ASSET_BUILD_OK',sum(len(o.data.polygons) for o in bpy.data.objects if o.type=='MESH'),'polygons',len([o for o in bpy.data.objects if o.type=='MESH']),'render meshes')
# Preserve solid material factors with glTF COLOR_0 on Blender 4.3.
exec(compile(open(os.path.join(os.path.dirname(__file__),'fix_gltf_colors.py')).read(),'fix_gltf_colors.py','exec'))
