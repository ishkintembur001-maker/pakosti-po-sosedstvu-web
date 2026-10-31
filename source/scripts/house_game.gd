extends Node3D
signal menu_requested
const H=3.35
const SPEED=3.4
const STAIR_BOTTOM=Vector2(6.8,2.75)
const STAIR_TOP=Vector2(6.8,-1.8)
const MODEL=preload("res://assets/models/two_storey.glb")
const CASES=[
 {"title":"Первый след", "floor":0,"kinds":[0],"targets":[Vector2(-4.1,1.1)]},
 {"title":"Красочный приём", "floor":0,"kinds":[1],"targets":[Vector2(3.7,1.1)]},
 {"title":"Субботний переполох", "floor":0,"kinds":[0,1,2],"targets":[Vector2(-4.1,1.1),Vector2(3.7,1.1),Vector2(0,1.1)]},
 {"title":"Праздник в гостиной", "floor":0,"kinds":[0,1,2,3],"targets":[Vector2(-4.1,1.1),Vector2(3.7,1.1),Vector2(0,1.1),Vector2(-1.2,1.1)]},
 {"title":"Пена на втором этаже", "floor":1,"kinds":[2],"targets":[Vector2(0,1.1)]},
 {"title":"Тапки с сюрпризом", "floor":1,"kinds":[0,3],"targets":[Vector2(-4.1,1.1),Vector2(3.7,1.1)]},
 {"title":"Два этажа хлопот", "floor":1,"kinds":[0,1,2],"targets":[Vector2(-4.1,1.1),Vector2(3.7,1.1),Vector2(0,1.1)]},
 {"title":"Весь дом вверх дном", "floor":1,"kinds":[0,1,2,3],"targets":[Vector2(-4.1,1.1),Vector2(3.7,1.1),Vector2(0,1.1),Vector2(-1.2,1.1)]}]
const NAMES=["Банан","Краска","Мыло","Конфетти"]
const COLORS=[Color("e5bf43"),Color("9e48b7"),Color("76cadd"),Color("de8166")]
var index=0
var floor_id=0
var player_pos=Vector2(4.2,1.1)
var neighbor_pos=Vector2(-4.1,1.1)
var neighbor_floor=0
var hero:Node3D
var neighbor:Node3D
var environment_root:Node3D
var camera:Camera3D
var actor_source:Node3D
var targets=[]
var supplies=[]
var inventory=[false,false,false,false]
var navs=[]
var player_path=PackedVector2Array()
var enemy_path=PackedVector2Array()
var waypoint=0
var route=[Vector2(-4.1,1.1),Vector2(0,1.1),Vector2(3.7,1.1),Vector2(0,1.1)]
var elapsed=0.0
var hidden=false
var state="playing"
var lives=3
var caught=0
var reaction=0.0
var reaction_kind=0
var alert=0.0
var face=Vector2.RIGHT
var safe_time=4.0
var climbing=0.0
var climb_from=0
var climb_to=1
var climb_start=Vector2.ZERO
var climb_end=Vector2.ZERO
var stick_id=-100
var stick=Vector2.ZERO
var action_time=0.0
var quality=true
var fps_time=0.0
var fps_frames=0
var hud:Control
var info:Label
var goal:Label
var action_button:Button
var result_panel:PanelContainer
var slice_materials=[]
var shadow:DirectionalLight3D
var sfx={}
var particles=[]
var hud_script=preload("res://scripts/house_hud.gd")

func _ready():
 actor_source=MODEL.instantiate();add_child(actor_source)
 environment_root=actor_source.find_child("TwoStoreyHouse",true,false)
 var source_hero=actor_source.find_child("TricksterCharacter",true,false)
 var source_neighbor=actor_source.find_child("NeighborCharacter",true,false)
 hero=source_hero.duplicate();add_child(hero);hero.position=Vector3.ZERO;hero.rotation=Vector3.ZERO
 neighbor=source_neighbor.duplicate();add_child(neighbor);neighbor.position=Vector3.ZERO;neighbor.rotation=Vector3.ZERO
 source_hero.hide();source_neighbor.hide()
 attach_animations(hero,"TricksterCharacter");attach_animations(neighbor,"NeighborCharacter")
 for c in actor_source.find_children("*","Camera3D",true,false):c.current=false
 for light in actor_source.find_children("*","Light3D",true,false):light.visible=false
 make_slices(environment_root)
 for f in range(2):navs.append(build_nav(f))
 camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=7.9;add_child(camera);camera.current=true
 shadow=DirectionalLight3D.new();shadow.rotation_degrees=Vector3(-55,-25,0);shadow.light_color=Color("fff4e5");shadow.light_energy=.48;shadow.shadow_enabled=true;shadow.directional_shadow_max_distance=32;add_child(shadow)
 var env=WorldEnvironment.new();var e=Environment.new();e.background_mode=Environment.BG_COLOR;e.background_color=Color("202a2e");e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color=Color("d1e0e4");e.ambient_light_energy=.32;e.tonemap_mode=Environment.TONE_MAPPER_FILMIC;env.environment=e;add_child(env)
 var canvas=CanvasLayer.new();add_child(canvas);hud=hud_script.new();hud.game=self;canvas.add_child(hud)
 for k in ["pickup","arm","prank","caught","victory"]:
  var p=AudioStreamPlayer.new();p.stream=load("res://assets/sfx/%s.wav"%k);p.bus="SFX";add_child(p);sfx[k]=p
 start_case(index)

func make_slices(node:Node):
 if node is MeshInstance3D:
  for i in range(node.mesh.get_surface_count()):
   var m=node.get_active_material(i)
   if not m is StandardMaterial3D:continue
   var shader=Shader.new();shader.code="shader_type spatial; render_mode cull_disabled; uniform vec4 tint:source_color=vec4(1.0); uniform sampler2D tex:source_color,filter_linear_mipmap_anisotropic,repeat_enable; uniform bool textured=false; uniform float cutoff=99.0; uniform float rough=0.8; uniform float metal=0.0; varying float wy; void vertex(){wy=(MODEL_MATRIX*vec4(VERTEX,1.0)).y;} void fragment(){if(wy>cutoff) discard; ALBEDO=tint.rgb*(textured?texture(tex,UV).rgb:vec3(1.0)); ROUGHNESS=rough;METALLIC=metal;}"
   var sm=ShaderMaterial.new();sm.shader=shader;sm.set_shader_parameter("tint",m.albedo_color);sm.set_shader_parameter("rough",m.roughness);sm.set_shader_parameter("metal",m.metallic)
   if m.albedo_texture:sm.set_shader_parameter("tex",m.albedo_texture);sm.set_shader_parameter("textured",true)
   node.set_surface_override_material(i,sm);slice_materials.append(sm)
 for c in node.get_children():make_slices(c)

func set_slice():
 for m in slice_materials:m.set_shader_parameter("cutoff",3.24 if floor_id==0 and climbing<=0 else 99.0)

func obstacles(f:int)->Array:
 # Furniture footprints match the authored house; corridor z=1.1 passes both doors.
 var a=[Rect2(-8,-3.1,16,.32),Rect2(-8,-3.1,.25,6.2),Rect2(7.75,-3.1,.25,6.2)]
 for x in [-2.69,2.62]:
  a.append(Rect2(x-.12,-3.1,.24,3.34));a.append(Rect2(x-.12,2.2,.24,.9))
 if f==0:
  a.append(Rect2(-7.25,-2.6,2.7,2.25));a.append(Rect2(-4.4,-2.65,1.1,1.1));a.append(Rect2(-1.8,-2.65,3.5,1.2));a.append(Rect2(-.95,-.75,1.8,.95));a.append(Rect2(4,-2.8,1.4,1.2))
 else:
  a.append(Rect2(-7.2,-2.75,2.4,2.8));a.append(Rect2(-1.9,-2.7,2.1,1.6));a.append(Rect2(3.2,-1.3,1.8,.86));a.append(Rect2(5.4,-1.5,2.4,4.6))
 return a
func blocked(p:Vector2,f:int)->bool:
 if absf(p.x)>7.55 or absf(p.y)>2.82:return true
 for r in obstacles(f):
  if r.grow(.19).has_point(p):return true
 return false
func build_nav(f:int)->AStarGrid2D:
 var nav=AStarGrid2D.new();nav.region=Rect2i(0,0,77,29);nav.cell_size=Vector2(.2,.2);nav.offset=Vector2(-7.6,-2.8);nav.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES;nav.update()
 for x in range(77):
  for y in range(29):nav.set_point_solid(Vector2i(x,y),blocked(nav.get_point_position(Vector2i(x,y)),f))
 return nav
func cell(p:Vector2,f:int)->Vector2i:
 var raw=Vector2i(clampi(roundi((p.x+7.6)/.2),0,76),clampi(roundi((p.y+2.8)/.2),0,28))
 if not navs[f].is_point_solid(raw):return raw
 var best=raw;var distance=1e9
 for x in range(77):
  for y in range(29):
   var c=Vector2i(x,y)
   if not navs[f].is_point_solid(c):
    var d=navs[f].get_point_position(c).distance_squared_to(p)
    if d<distance:distance=d;best=c
 return best
func path(a:Vector2,b:Vector2,f:int)->PackedVector2Array:return navs[f].get_point_path(cell(a,f),cell(b,f))
func start_case(n:int):
 if is_instance_valid(hud) and is_instance_valid(hud.result):hud.result.queue_free();hud.result=null
 index=clampi(n,0,CASES.size()-1);floor_id=0;neighbor_floor=int(CASES[index].floor);player_pos=Vector2(4.2,1.1);neighbor_pos=Vector2(-4.1,1.1)
 for t in targets:t.node.queue_free()
 for t in supplies:t.node.queue_free()
 targets.clear();supplies.clear();inventory=[false,false,false,false];lives=3;caught=0;elapsed=0;action_time=0;stick=Vector2.ZERO;hidden=false;reaction=0;safe_time=4;alert=0;climbing=0;state="playing";player_path.clear();enemy_path.clear();waypoint=1
 for i in range(CASES[index].kinds.size()):
  var kind=CASES[index].kinds[i];var p:Vector2=CASES[index].targets[i]
  var marker=make_marker(p,neighbor_floor,kind,false)
  targets.append({"kind":kind,"pos":p,"floor":neighbor_floor,"armed":false,"used":false,"node":marker})
  var supply_pos=[Vector2(4.2,2.45),Vector2(3.3,.25),Vector2(5.1,.2),Vector2(5.2,2.35)][i]
  var supply=make_marker(supply_pos,0,kind,true)
  supplies.append({"kind":kind,"pos":supply_pos,"floor":0,"taken":false,"node":supply})
 set_slice();hud.refresh()
func make_marker(p:Vector2,f:int,kind:int,supply:bool)->Node3D:
 var n=Node3D.new();n.position=Vector3(p.x,.23+f*H,p.y);add_child(n)
 var mesh=MeshInstance3D.new();var ring=TorusMesh.new();ring.inner_radius=.28;ring.outer_radius=.32;ring.rings=20;ring.ring_segments=8;mesh.mesh=ring
 var m=StandardMaterial3D.new();m.albedo_color=COLORS[kind];m.emission_enabled=true;m.emission=COLORS[kind];m.emission_energy_multiplier=.25;mesh.material_override=m;n.add_child(mesh)
 var label=Label3D.new();label.text=("ВЗЯТЬ: " if supply else "")+NAMES[kind];label.font_size=28;label.pixel_size=.009;label.position.y=.58;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.no_depth_test=false;n.add_child(label)
 if supply:
  var icon=MeshInstance3D.new();var sphere=SphereMesh.new();sphere.radius=.12;sphere.height=.24;icon.mesh=sphere;icon.material_override=m;icon.position.y=.2;n.add_child(icon)
 return n
func hint()->String:
 if climbing>0:return "ЛЕСТНИЦА"
 if hidden:return "ВЫЙТИ ИЗ УКРЫТИЯ"
 for s in supplies:
  if not s.taken and floor_id==s.floor and player_pos.distance_to(s.pos)<.95:return "ВЗЯТЬ: "+NAMES[s.kind]
 for t in targets:
  if not t.used and not t.armed and floor_id==t.floor and player_pos.distance_to(t.pos)<.95:return ("УСТАНОВИТЬ: " if inventory[t.kind] else "НАЙДИ: ")+NAMES[t.kind]
 if near_stair():return "ПОДНЯТЬСЯ" if floor_id==0 else "СПУСТИТЬСЯ"
 if near_hide():return "СПРЯТАТЬСЯ"
 return "ДЕЙСТВИЕ"
func near_stair()->bool:
 return player_pos.distance_to(Vector2(6.7,1.8) if floor_id==0 else Vector2(5.0,-2.15))<1.1
func near_hide()->bool:return player_pos.distance_to(Vector2(-7.1,1.5))<1 or player_pos.distance_to(Vector2(3.25,2.5))<1
func act():
 if state!="playing" or climbing>0:return
 if hidden:hidden=false;return
 for s in supplies:
  if not s.taken and floor_id==s.floor and player_pos.distance_to(s.pos)<.95:
   s.taken=true;s.node.hide();inventory[s.kind]=true;play("pickup");action_time=.55;return
 for t in targets:
  if not t.used and not t.armed and floor_id==t.floor and player_pos.distance_to(t.pos)<.95:
   if inventory[t.kind]:t.armed=true;inventory[t.kind]=false;play("arm");action_time=.8
   return
 if near_stair():start_climb();return
 if near_hide():hidden=true;player_path.clear()
func start_climb():
 climbing=3.1;climb_from=floor_id;climb_to=1-floor_id;climb_start=player_pos;climb_end=Vector2(5.0,-2.15) if floor_id==0 else Vector2(6.7,1.8);hidden=false;player_path.clear();set_slice()
func finish_prank(t):
 t.used=true;t.armed=false;t.node.hide();reaction=2.7;reaction_kind=t.kind;play("prank")
 for i in range(14):
  var p=MeshInstance3D.new();var mesh=SphereMesh.new();mesh.radius=.04;mesh.height=.08;p.mesh=mesh
  var m=StandardMaterial3D.new();m.albedo_color=COLORS[t.kind];p.material_override=m;p.position=Vector3(t.pos.x,.8+t.floor*H,t.pos.y);add_child(p);particles.append({"node":p,"velocity":Vector3(randf_range(-1.5,1.5),randf_range(1.2,2.5),randf_range(-1.5,1.5)),"life":1.5})
 if targets.all(func(item):return item.used):
  state="won";play("victory");var cfg=ConfigFile.new();cfg.load("user://pakosti_release.cfg");var unlocked=maxi(int(cfg.get_value("house","unlocked",0)),mini(index+1,7));cfg.set_value("house","unlocked",unlocked);cfg.set_value("house","last",mini(index+1,7));cfg.set_value("scores",str(index),maxi(int(cfg.get_value("scores",str(index),0)),maxi(100,1000-int(elapsed)*2-caught*150)));cfg.save("user://pakosti_release.cfg");hud.show_result(true)
func play(k:String):sfx[k].play()
func tick_enemy(dt:float):
 if reaction>0:
  reaction=maxf(0,reaction-dt);return
 var diff=player_pos-neighbor_pos
 var can_see=floor_id==neighbor_floor and not hidden and climbing<=0 and safe_time<=0 and diff.length()<3.1 and diff.normalized().dot(face)>.15 and clear_line(neighbor_pos,player_pos,neighbor_floor)
 alert=clampf(alert+dt*(1.1 if can_see else -.65),0,1)
 var dest:Vector2=player_pos if alert>.85 else route[waypoint]
 if neighbor_pos.distance_to(dest)<.15 and alert<=.85:waypoint=(waypoint+1)%route.size();dest=route[waypoint]
 if enemy_path.is_empty() or (alert>.85 and int(elapsed*4)%3==0):enemy_path=path(neighbor_pos,dest,neighbor_floor)
 while not enemy_path.is_empty() and neighbor_pos.distance_to(enemy_path[0])<.055:enemy_path.remove_at(0)
 if not enemy_path.is_empty():
  var step=enemy_path[0]-neighbor_pos;face=step.normalized();neighbor_pos+=step.limit_length(dt*(2.3 if alert>.85 else 1.15+index*.035))
 for t in targets:
  if t.armed and not t.used and neighbor_floor==t.floor and neighbor_pos.distance_to(t.pos)<.45:finish_prank(t);return
 if can_see and diff.length()<.5:
  lives-=1;caught+=1;play("caught");safe_time=4;player_pos=Vector2(4.2,1.1);floor_id=0;player_path.clear();alert=0;set_slice()
  if lives<=0:state="lost";hud.show_result(false)
func clear_line(a:Vector2,b:Vector2,f:int)->bool:
 for i in range(1,15):
  if blocked(a.lerp(b,float(i)/15),f):return false
 return true
func _process(dt:float):
 if state=="won":animate(hero,0,99)
 elapsed+=dt;safe_time=maxf(0,safe_time-dt);action_time=maxf(0,action_time-dt)
 if state=="playing":
  if climbing>0:
   climbing=maxf(0,climbing-dt);var t=1-climbing/3.1
   # Walk to the stairs, ascend their 18 physical risers, then step onto landing.
   var p:Vector2;var height:float
   if t<.18:p=climb_start.lerp(STAIR_BOTTOM if climb_from==0 else STAIR_TOP,t/.18);height=climb_from*H
   elif t<.82:
    var s=(t-.18)/.64;p=(STAIR_BOTTOM if climb_from==0 else STAIR_TOP).lerp(STAIR_TOP if climb_from==0 else STAIR_BOTTOM,s);height=lerpf(climb_from*H,climb_to*H,s)
   else:p=(STAIR_TOP if climb_from==0 else STAIR_BOTTOM).lerp(climb_end,(t-.82)/.18);height=climb_to*H
   hero.position=Vector3(p.x,.2+height,p.y);animate(hero,1,0)
   if climbing<=0:floor_id=climb_to;player_pos=climb_end;set_slice()
  else:move_player(dt)
  tick_enemy(dt)
 neighbor.position=Vector3(neighbor_pos.x,.2+neighbor_floor*H,neighbor_pos.y)
 neighbor.rotation.y=atan2(face.x,face.y);animate(neighbor,0 if reaction>0 else 1,reaction_kind+1 if reaction>0 else 0)
 hero.visible=not hidden;neighbor.visible=neighbor_floor==floor_id or climbing>0
 var focus=hero.position+Vector3(0,.8,0);var target=Vector3(clampf(focus.x,-3,3),focus.y,0)
 camera.position=target+Vector3(1.2,7.5,17);camera.look_at(target)
 for i in range(particles.size()-1,-1,-1):
  var p=particles[i];p.life-=dt;p.node.position+=p.velocity*dt;p.velocity.y-=dt*4
  if p.life<=0:p.node.queue_free();particles.remove_at(i)
 fps_time+=dt;fps_frames+=1
 if fps_time>4 and quality:
  if fps_frames/fps_time<25:set_quality(false)
  fps_time=0;fps_frames=0
 hud.refresh()
func move_player(dt:float):
 var input=Input.get_vector("ui_left","ui_right","ui_up","ui_down")+stick
 if Input.is_key_pressed(KEY_A):input.x-=1
 if Input.is_key_pressed(KEY_D):input.x+=1
 if Input.is_key_pressed(KEY_W):input.y-=1
 if Input.is_key_pressed(KEY_S):input.y+=1
 input=input.limit_length(1);var motion=Vector2.ZERO
 if input.length()>.1:
  player_path.clear();motion=input;hidden=false
 elif not player_path.is_empty():
  while not player_path.is_empty() and player_pos.distance_to(player_path[0])<.055:player_path.remove_at(0)
  if not player_path.is_empty():motion=(player_path[0]-player_pos).normalized()
 if not hidden and action_time<=0:
  var step=motion*SPEED*dt
  for axis in [Vector2(step.x,0),Vector2(0,step.y)]:
   if not blocked(player_pos+axis,floor_id):player_pos+=axis
 hero.position=Vector3(player_pos.x,.2+floor_id*H,player_pos.y)
 if motion.length()>.1:hero.rotation.y=lerp_angle(hero.rotation.y,atan2(motion.x,motion.y),minf(1,dt*12))
 animate(hero,motion.length() if action_time<=0 else 0,-1 if action_time>0 else 0)
func attach_animations(actor:Node3D,source_name:String):
 var source=actor_source.find_child("AnimationPlayer",true,false)
 if not source is AnimationPlayer:return
 var player=AnimationPlayer.new();player.name="ActorAnimations";actor.add_child(player)
 var library=AnimationLibrary.new()
 for clip in source.get_animation_list():
  if clip=="RESET":continue
  var animation:Animation=source.get_animation(clip).duplicate(true)
  for track in range(animation.get_track_count()-1,-1,-1):
   var p=String(animation.track_get_path(track));var marker=source_name+"/";var at=p.find(marker)
   if at<0:animation.remove_track(track)
   else:animation.track_set_path(track,NodePath(p.substr(at+marker.length())))
  if animation.get_track_count()==0:continue
  var name=String(clip).get_file()
  animation.loop_mode=Animation.LOOP_LINEAR if name in ["idle","walk","sneak","run"] else Animation.LOOP_NONE
  library.add_animation(name,animation)
 player.add_animation_library("",library)
 actor.set_meta("animation_player",player)
func animate(actor:Node3D,speed:float,pose:int):
 if actor.has_meta("animation_player"):
  var player:AnimationPlayer=actor.get_meta("animation_player")
  var clip="walk" if speed>.1 else "idle"
  if pose==99:clip="celebrate"
  elif pose==-1:clip="plant_trap"
  elif pose in [1,3]:clip="react_slip"
  elif pose>0:clip="react_surprise"
  if player.has_animation(clip) and player.current_animation!=clip:player.play(clip,.16)
  player.speed_scale=maxf(.65,speed) if clip=="walk" else 1.0
 actor.rotation.z=sin(elapsed*12)*.12 if pose in [1,3] else 0
func set_quality(enabled:bool):
 quality=enabled;shadow.shadow_enabled=enabled;get_viewport().scaling_3d_scale=1 if enabled else .7
func click_world(p:Vector2):
 if state!="playing" or hidden or climbing>0:return
 var origin=camera.project_ray_origin(p);var direction=camera.project_ray_normal(p);var hit=Plane(Vector3.UP,.2+floor_id*H).intersects_ray(origin,direction)
 if hit!=null:player_path=path(player_pos,Vector2(hit.x,hit.z),floor_id)
func handle_touch(i:int,p:Vector2,pressed:bool):
 if pressed:
  if p.distance_to(Vector2(100,451))<84:stick_id=i;stick=(p-Vector2(100,451))/54.0;stick=stick.limit_length(1)
 else:
  if i==stick_id:stick_id=-100;stick=Vector2.ZERO
func _unhandled_input(e):
 if e is InputEventScreenTouch:
  handle_touch(e.index,e.position,e.pressed)
  if e.pressed and e.position.y<385:click_world(e.position)
 elif e is InputEventScreenDrag and e.index==stick_id:stick=((e.position-Vector2(100,451))/54.0).limit_length(1)
 elif e is InputEventMouseButton and e.button_index==MOUSE_BUTTON_LEFT:
  handle_touch(-1,e.position,e.pressed)
  if e.pressed and e.position.y<385:click_world(e.position)
 elif e is InputEventMouseMotion and stick_id==-1:stick=((e.position-Vector2(100,451))/54.0).limit_length(1)
 elif e is InputEventKey and e.pressed and not e.echo:
  if e.keycode in [KEY_E,KEY_SPACE]:act()
  elif e.keycode==KEY_ESCAPE:menu_requested.emit()
  elif e.keycode==KEY_Q:set_quality(not quality)
func _notification(what):
 if what==NOTIFICATION_APPLICATION_FOCUS_OUT:stick=Vector2.ZERO;stick_id=-100;player_path.clear()

func _exit_tree():
 for player in sfx.values():
  if is_instance_valid(player):player.stop()
