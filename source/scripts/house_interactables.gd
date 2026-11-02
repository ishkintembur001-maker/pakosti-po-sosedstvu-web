extends Node3D
## Doors and searchable furniture. Owner GLBs are never modified.
var game
var doors:Array=[]
var caches:Array=[]
var found_details:int=0
const DOOR_X=[-2.69,2.62]
const CACHE_DATA=[
 [Vector2(-6.15,1.86),0,"Шкаф"],
 [Vector2(-1.35,1.86),0,"Ящик комода"],
 [Vector2(4.35,1.86),0,"Тумба"],
 [Vector2(-6.15,1.86),1,"Комод"],
 [Vector2(-1.35,1.86),1,"Полка"],
 [Vector2(4.35,1.86),1,"Коробка"]
]
func add_box(parent:Node3D,at:Vector3,size:Vector3,color:Color)->MeshInstance3D:
 var box=MeshInstance3D.new()
 var mesh=BoxMesh.new();mesh.size=size;box.mesh=mesh
 var material=StandardMaterial3D.new();material.albedo_color=color;material.roughness=.74
 box.material_override=material;box.position=at;parent.add_child(box)
 return box
func add_label(parent:Node3D,title:String,position:Vector3)->Label3D:
 var caption=Label3D.new();caption.text=title;caption.font_size=25;caption.pixel_size=.005
 caption.position=position;caption.billboard=BaseMaterial3D.BILLBOARD_ENABLED
 caption.modulate=Color("f5dca3");caption.outline_size=7;parent.add_child(caption)
 return caption
func build()->void:
 for floor in range(2):
  for index in range(DOOR_X.size()):
   var x:float=DOOR_X[index]
   var pos=Vector2(x,1.10)
   var anchor=Node3D.new();anchor.name="PlayableDoor_%d_%d"%[floor,index]
   anchor.position=Vector3(x,game.floor_height(pos,floor),.35)
   add_child(anchor)
   var panel=Node3D.new();panel.name="HingedDoor";anchor.add_child(panel)
   add_box(panel,Vector3(0,1.10,.76),Vector3(.09,2.2,1.52),Color("765239"))
   add_box(panel,Vector3(-.085,1.07,1.31),Vector3(.095,.13,.13),Color("d9bc76"))
   var caption=add_label(anchor,"ОТКРЫТЬ ДВЕРЬ",Vector3(0,2.35,.76))
   doors.append({"id":doors.size(),"floor":floor,"pos":pos,"panel":panel,"node":anchor,
    "label":caption,"open":false,"angle":0.0,"timer":0.0})
 reset_caches(0)
func reset_doors()->void:
 for door in doors:
  door.open=false;door.angle=0.0;door.timer=0.0
  door.panel.rotation.y=0.0
  door.label.text="ОТКРЫТЬ ДВЕРЬ"
func reset_caches(mission:int)->void:
 for cache in caches:
  if is_instance_valid(cache.node):cache.node.queue_free()
 caches.clear();found_details=0
 var tasks:Array=game.CASES[mission].tasks
 for idx in range(CACHE_DATA.size()):
  var definition:Array=CACHE_DATA[idx]
  var pos:Vector2=definition[0];var floor:int=definition[1];var title:String=definition[2]
  var root=Node3D.new();root.name="Searchable_%d"%idx
  root.position=Vector3(pos.x,game.floor_height(pos,floor),pos.y)
  add_child(root)
  add_box(root,Vector3(0,.22,0),Vector3(.64,.42,.43),Color("66503b"))
  var drawer=Node3D.new();drawer.name="SearchableDrawer";root.add_child(drawer)
  add_box(drawer,Vector3(0,.25,.25),Vector3(.54,.27,.065),Color("a67c50"))
  add_box(drawer,Vector3(0,.25,.303),Vector3(.14,.055,.045),Color("d7be86"))
  var caption=add_label(root,"ОБЫСКАТЬ: "+title,Vector3(0,.80,0))
  var kind:int=int(tasks[(idx+mission)%tasks.size()][0])
  caches.append({"id":idx,"pos":pos,"floor":floor,"title":title,
   "kind":kind,"used":false,"node":root,"drawer":drawer,"label":caption})
func door_at(pos:Vector2,floor:int,radius:float=1.20)->Dictionary:
 var best:Dictionary={};var distance:float=radius
 for door in doors:
  if door.floor!=floor:continue
  var d:float=door.pos.distance_to(pos)
  if d<distance:best=door;distance=d
 return best
func cache_at(pos:Vector2,floor:int,radius:float=1.15)->Dictionary:
 var best:Dictionary={};var distance:float=radius
 for cache in caches:
  if cache.floor!=floor or cache.used:continue
  var d:float=cache.pos.distance_to(pos)
  if d<distance:best=cache;distance=d
 return best
func approach(pos:Vector2,from_pos:Vector2)->Vector2:
 return Vector2(pos.x+(-.73 if from_pos.x<pos.x else .73),pos.y)
func set_open(door:Dictionary,opened:bool)->bool:
 if door.is_empty() or door.open==opened:return false
 if not opened:
  if door.pos.distance_to(game.player_pos)<1.25:return false
  if door.floor==game.neighbor_floor and door.pos.distance_to(game.neighbor_pos)<1.25:return false
 door.open=opened
 door.timer=8.0 if opened else 0.0
 door.label.text="ЗАКРЫТЬ ДВЕРЬ" if opened else "ОТКРЫТЬ ДВЕРЬ"
 if opened:game.report_noise(door.pos,door.floor,.18)
 game.show_notice("ДВЕРЬ ОТКРЫТА" if opened else "ДВЕРЬ ЗАКРЫТА")
 return true
func toggle(index:int)->bool:
 if index<0 or index>=doors.size():return false
 var door:Dictionary=doors[index]
 if door.floor!=game.floor_id or door.pos.distance_to(game.player_pos)>1.4:return false
 return set_open(door,not door.open)
func search(index:int)->bool:
 if index<0 or index>=caches.size():return false
 var cache:Dictionary=caches[index]
 if cache.floor!=game.floor_id or cache.used or cache.pos.distance_to(game.player_pos)>1.15:return false
 cache.used=true;found_details+=1
 game.inventory[cache.kind]+=1
 game.play("pickup");game.action_time=.55
 game.report_noise(cache.pos,cache.floor,.35)
 game.show_notice("НАЙДЕНО В %s: %s"%[cache.title.to_upper(),game.NAMES[cache.kind].to_upper()])
 cache.label.text="ОБЫСКАНО"
 cache.drawer.position.z=.28
 return true
func obstructs_step(pos:Vector2,floor:int)->bool:
 for door in doors:
  if door.floor!=floor or door.open:continue
  if absf(pos.x-door.pos.x)<.25 and absf(pos.y-door.pos.y)<.88:
   set_open(door,true)
   return true
 return false
func opaque_at(pos:Vector2,floor:int)->bool:
 for door in doors:
  if door.floor==floor and not door.open:
   if absf(pos.x-door.pos.x)<.12 and absf(pos.y-door.pos.y)<.81:return true
 return false
func clicked(screen:Vector2,floor:int)->Dictionary:
 var candidate:Dictionary={};var best:float=58.0
 for cache in caches:
  if cache.floor!=floor or cache.used:continue
  var projected=game.camera.unproject_position(Vector3(cache.pos.x,game.floor_height(cache.pos,floor)+.75,cache.pos.y))
  var distance:float=projected.distance_to(screen)
  if distance<best:best=distance;candidate={"type":"search","id":cache.id,"pos":cache.pos}
 for door in doors:
  if door.floor!=floor:continue
  var projected=game.camera.unproject_position(Vector3(door.pos.x,game.floor_height(door.pos,floor)+1.5,door.pos.y))
  var distance:float=projected.distance_to(screen)
  if distance<best:best=distance;candidate={"type":"door","id":door.id,"pos":door.pos}
 return candidate
func _process(dt:float)->void:
 if game==null or game.paused:return
 for door in doors:
  var goal:float=1.33 if door.open else 0.0
  door.angle=move_toward(float(door.angle),goal,dt*3.4)
  door.panel.rotation.y=door.angle
  if door.open:
   door.timer-=dt
   if door.timer<=0.0:set_open(door,false)
 for cache in caches:
  if cache.used:cache.drawer.position.z=move_toward(cache.drawer.position.z,.32,dt*.9)
