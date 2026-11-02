extends Node3D
signal menu_requested
const H=3.35
const SPEED=3.4
const STAIR_BOTTOM=Vector2(6.8,2.75)
const STAIR_TOP=Vector2(6.8,-1.8)
const MODEL=preload("res://assets/models/two_storey.glb")
const CUTAWAY_SHADER=preload("res://shaders/cutaway.gdshader")
const CONTACT_SHADER=preload("res://shaders/contact_shadow.gdshader")
const EXIT_POS=Vector2(4.2,1.1)
const TRAP_SPOTS=[Vector2(-4.1,1.1),Vector2(-3.2,1.1),Vector2(-2.25,1.1),Vector2(-1.2,1.1),Vector2(0,1.1),Vector2(1.1,1.1),Vector2(2.2,1.1),Vector2(3.7,1.1)]
const SUPPLY_SPOTS=[Vector2(-6.55,1.85),Vector2(-4.85,1.85),Vector2(-3.35,1.85),Vector2(-1.85,1.85),Vector2(-.45,1.85),Vector2(1.4,1.85),Vector2(3.5,1.85),Vector2(5.25,1.85)]
const CASES=[
 {"id":"m01","chapter":1,"title":"Первый след","floor":0,"goal":"Подготовь прихожую и уйди незаметно","bonus":"Без подсказки пройти за спиной соседа","bonus_rule":"clean","par":240,"difficulty":0,"tasks":[[0,0,"Кожура у ковра"],[4,2,"Пищалка под креслом"],[3,4,"Конфетти у порога"],[2,7,"Мыльная дорожка"]]},
 {"id":"m02","chapter":1,"title":"Музыкальное кресло","floor":0,"goal":"Заставь кресло издавать смешные звуки","bonus":"Установить пищалку без погони","bonus_rule":"clean","par":254,"difficulty":0,"tasks":[[4,7,"Пищалка под креслом"],[4,4,"Шумная подушка"],[4,2,"Музыкальное кресло"],[7,0,"Шуточная наклейка"]]},
 {"id":"m03","chapter":1,"title":"Красочный привет","floor":0,"goal":"Создай серию цветных следов","bonus":"Уйти до начала осмотра","bonus_rule":"fast","par":268,"difficulty":0,"tasks":[[1,2,"Смываемый отпечаток"],[1,0,"Красочный след"],[1,7,"Краска на коврике"],[3,4,"Бумажный сюрприз"]]},
 {"id":"m04","chapter":1,"title":"Один шаг до комбо","floor":0,"goal":"Свяжи сюрпризы в гостиной","bonus":"Обе реакции в одном окне комбо","bonus_rule":"combo2","par":282,"difficulty":0,"tasks":[[0,4,"Кожура у ковра"],[4,7,"Пищалка под креслом"],[0,0,"Кожура на обратном пути"],[4,2,"Музыкальное кресло"],[3,6,"Конфетти у порога"]]},
 {"id":"m05","chapter":2,"title":"Пенный капучино","floor":0,"goal":"Подготовь шуточный завтрак","bonus":"Не трогать предметы после сервировки","bonus_rule":"clean","par":296,"difficulty":0,"tasks":[[5,0,"Пенный капучино"],[5,4,"Пенный стакан"],[6,7,"Игрушечный флажок"],[2,2,"Мыльная дорожка"],[0,5,"Скользкий сюрприз"]]},
 {"id":"m06","chapter":2,"title":"Оживший тостер","floor":0,"goal":"Сыграй на игрушечных сигналах","bonus":"Попасть в нужный момент без повторной попытки","bonus_rule":"combo2","par":310,"difficulty":1,"tasks":[[6,7,"Игрушечный флажок"],[6,2,"Игрушечный сигнал"],[4,4,"Звуковой сигнал"],[7,0,"Забавные карточки"],[5,3,"Пенный стакан"]]},
 {"id":"m07","chapter":2,"title":"Обед наоборот","floor":0,"goal":"Перепутай столовую сервировку","bonus":"Правильная раскладка с первой попытки","bonus_rule":"fast","par":324,"difficulty":1,"tasks":[[7,0,"Забавные карточки"],[7,2,"Подмена карточек"],[7,4,"Шуточная наклейка"],[3,7,"Конфетти у порога"],[1,1,"Красочный след"]]},
 {"id":"m08","chapter":2,"title":"Завтрак по цепочке","floor":0,"goal":"Соедини шесть утренних пакостей","bonus":"Три реакции без разрыва комбо","bonus_rule":"combo3","par":338,"difficulty":1,"tasks":[[5,7,"Пенный капучино"],[5,4,"Пенный стакан"],[4,2,"Пищалка под креслом"],[6,0,"Игрушечный флажок"],[2,6,"Мыльная дорожка"],[0,5,"Кожура у ковра"]]},
 {"id":"m09","chapter":3,"title":"Король пены","floor":1,"goal":"Устрой пенную уборку наверху","bonus":"Не пользоваться подсветкой маршрута","bonus_rule":"clean","par":352,"difficulty":1,"tasks":[[5,2,"Пузырьки в ванной"],[5,0,"Пена для уборки"],[2,7,"Пенная ловушка"],[2,4,"Мыльная дорожка"],[2,1,"Мыло у двери"]]},
 {"id":"m10","chapter":3,"title":"Большая стирка","floor":1,"goal":"Перепутай ярлыки и бельё","bonus":"Развесить всё без сброса пазла","bonus_rule":"fast","par":366,"difficulty":1,"tasks":[[7,4,"Подмена карточек"],[7,7,"Шуточная наклейка"],[5,0,"Пена для уборки"],[3,2,"Конфетти у порога"],[5,6,"Пенный стакан"]]},
 {"id":"m11","chapter":3,"title":"Тапки не на месте","floor":1,"goal":"Запутай соседа звуками и следами","bonus":"Не вызвать проверку пропавшего предмета","bonus_rule":"clean","par":380,"difficulty":2,"tasks":[[4,0,"Шумная подушка"],[0,4,"Скользкий сюрприз"],[4,7,"Музыкальное кресло"],[0,2,"Кожура на обратном пути"],[3,5,"Бумажный сюрприз"],[1,1,"Смываемый отпечаток"]]},
 {"id":"m12","chapter":3,"title":"Генеральная пакость","floor":1,"goal":"Свяжи шесть розыгрышей наверху","bonus":"Закончить без погони на лестнице","bonus_rule":"combo3","par":394,"difficulty":2,"tasks":[[5,7,"Пузырьки в ванной"],[2,2,"Пенная ловушка"],[7,4,"Подмена карточек"],[4,0,"Шумная подушка"],[1,3,"Смываемый отпечаток"],[3,5,"Праздничный хлопок"]]},
 {"id":"m13","chapter":4,"title":"Сигнал из гаража","floor":0,"goal":"Размести игрушечные сигналы","bonus":"Машинка не должна застрять","bonus_rule":"fast","par":408,"difficulty":2,"tasks":[[6,0,"Игрушечная машинка"],[6,2,"Игрушечный сигнал"],[4,4,"Звуковой сигнал"],[6,7,"Игрушечный флажок"],[7,1,"Шуточная наклейка"],[2,3,"Мыло у двери"]]},
 {"id":"m14","chapter":4,"title":"Пернатый концерт","floor":1,"goal":"Заставь соседа искать игрушечную птицу","bonus":"Не попадать в поле зрения из окна","bonus_rule":"clean","par":422,"difficulty":2,"tasks":[[6,7,"Игрушечная птица"],[4,4,"Звуковой сигнал"],[6,2,"Игрушечный сигнал"],[5,0,"Пенный стакан"],[3,6,"Бумажный сюрприз"],[2,5,"Мыльная дорожка"]]},
 {"id":"m15","chapter":4,"title":"Живой портрет","floor":1,"goal":"Подготовь забавные портреты","bonus":"Одна точная активация","bonus_rule":"clean","par":436,"difficulty":2,"tasks":[[7,2,"Глаза на портрете"],[7,0,"Бумажные тени"],[7,7,"Шуточная наклейка"],[7,4,"Подмена карточек"],[1,1,"Смываемый отпечаток"],[3,5,"Конфетти у порога"]]},
 {"id":"m16","chapter":4,"title":"Хобби под контролем","floor":1,"goal":"Соедини шумы и бумажные обманки","bonus":"Ни одного лишнего отвлечения","bonus_rule":"combo3","par":450,"difficulty":3,"tasks":[[6,4,"Игрушечная машинка"],[6,7,"Игрушечная птица"],[7,0,"Глаза на портрете"],[4,2,"Звуковой сигнал"],[2,6,"Мыльная дорожка"],[1,3,"Смываемый отпечаток"],[3,1,"Бумажный сюрприз"]]},
 {"id":"m17","chapter":5,"title":"Подарок с характером","floor":0,"goal":"Подготовь подарки и сюрпризы","bonus":"Не уронить коробку при переносе","bonus_rule":"clean","par":464,"difficulty":3,"tasks":[[3,0,"Сюрприз в подарке"],[3,4,"Праздничный хлопок"],[3,7,"Конфетти у порога"],[7,2,"Забавные карточки"],[5,5,"Пенный стакан"],[0,1,"Кожура у ковра"],[1,3,"Красочный след"]]},
 {"id":"m18","chapter":5,"title":"Оркестр стульев","floor":0,"goal":"Устрой музыкальный переполох","bonus":"Выбрать правильный стул сразу","bonus_rule":"combo3","par":478,"difficulty":3,"tasks":[[4,7,"Пищалки на стульях"],[4,2,"Музыкальное кресло"],[4,4,"Шумная подушка"],[4,0,"Звуковой сигнал"],[4,3,"Пищалка под креслом"],[7,5,"Забавные карточки"],[7,6,"Подмена карточек"]]},
 {"id":"m19","chapter":5,"title":"Театр теней","floor":1,"goal":"Создай театр бумажных теней","bonus":"Совпасть с силуэтом с первой настройки","bonus_rule":"fast","par":492,"difficulty":3,"tasks":[[7,0,"Бумажные тени"],[7,2,"Глаза на портрете"],[7,4,"Шуточная наклейка"],[1,7,"Красочный след"],[6,1,"Игрушечная птица"],[3,3,"Бумажный сюрприз"],[6,5,"Игрушечный флажок"]]},
 {"id":"m20","chapter":5,"title":"Репетиция праздника","floor":0,"goal":"Устрой праздник из семи пакостей","bonus":"Избежать обоих наблюдателей","bonus_rule":"combo3","par":506,"difficulty":3,"tasks":[[3,7,"Сюрприз в подарке"],[3,4,"Праздничный хлопок"],[4,2,"Пищалки на стульях"],[3,0,"Конфетти у порога"],[4,6,"Пищалка под креслом"],[6,5,"Игрушечный флажок"],[7,3,"Забавные карточки"]]},
 {"id":"m21","chapter":6,"title":"Сосед настороже","floor":1,"goal":"Обойди настороженного соседа","bonus":"Не использовать старое укрытие","bonus_rule":"clean","par":520,"difficulty":4,"tasks":[[0,2,"Кожура на обратном пути"],[4,0,"Звуковой сигнал"],[6,7,"Игрушечный сигнал"],[7,4,"Глаза на портрете"],[1,1,"Смываемый отпечаток"],[2,5,"Мыльная дорожка"],[2,3,"Мыло у двери"],[3,6,"Праздничный хлопок"]]},
 {"id":"m22","chapter":6,"title":"Два взгляда","floor":1,"goal":"Соедини звуки и обманки","bonus":"Ни одного одновременного обнаружения","bonus_rule":"combo3","par":534,"difficulty":4,"tasks":[[6,4,"Игрушечная птица"],[7,7,"Бумажные тени"],[7,0,"Глаза на портрете"],[6,2,"Игрушечная машинка"],[4,6,"Звуковой сигнал"],[2,3,"Мыльная дорожка"],[3,1,"Бумажный сюрприз"],[5,5,"Пенный стакан"]]},
 {"id":"m23","chapter":6,"title":"Большая подготовка","floor":1,"goal":"Размести восемь сюрпризов","bonus":"Без сброса подготовленных объектов","bonus_rule":"fast","par":548,"difficulty":4,"tasks":[[5,0,"Пузырьки в ванной"],[7,4,"Подмена карточек"],[4,7,"Шумная подушка"],[7,2,"Глаза на портрете"],[7,5,"Бумажные тени"],[3,1,"Бумажный сюрприз"],[2,3,"Мыло у двери"],[4,6,"Звуковой сигнал"]]},
 {"id":"m24","chapter":6,"title":"Весь дом вверх дном","floor":1,"goal":"Устрой финальную цепочку пакостей","bonus":"Идеальная цепочка и ноль обнаружений","bonus_rule":"combo4","par":562,"difficulty":4,"tasks":[[3,7,"Праздничный хлопок"],[5,2,"Пузырьки в ванной"],[7,4,"Глаза на портрете"],[4,0,"Музыкальное кресло"],[7,3,"Бумажные тени"],[2,5,"Пенная ловушка"],[1,6,"Краска на коврике"],[7,1,"Забавные карточки"]]}
]
const NAMES=["Банан","Краска","Мыло","Конфетти","Пищалка","Пена","Игрушка","Бумажная шутка"]
const COLORS=[Color("e5bf43"),Color("9e48b7"),Color("76cadd"),Color("de8166"),Color("e09cc2"),Color("8ce1e3"),Color("a3ca61"),Color("d9d0b7")]
var paused=false
var stick_center=Vector2(108,426)
var pending_target=Vector2.INF
var pending_action=""
var escape_ready=false
var escape_route=false
var exit_marker:Node3D
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
var inventory=[0,0,0,0,0,0,0,0]
var navs=[]
var player_path=PackedVector2Array()
var enemy_path=PackedVector2Array()
var enemy_climbing=0.0
var enemy_climb_from=0
var enemy_climb_to=0
var enemy_climb_start=Vector2.ZERO
var enemy_climb_end=Vector2.ZERO
var enemy_stair_world=Vector3.ZERO
var enemy_search_time=0.0
var waypoint=0
var route=[Vector2(-4.1,1.1),Vector2(0,1.1),Vector2(3.7,1.1),Vector2(0,1.1)]
var elapsed=0.0
var hidden=false
var state="playing"
var lives=3
var caught=0
var reaction=0.0
var reaction_kind=0
var anger=0.0
var anger_events=0
var bonus_awarded=false
var combo=0
var best_combo=0
var combo_timer=0.0
var capture_time=0.0
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
var floor_data:Dictionary={}
var hero_contact:MeshInstance3D
var neighbor_contact:MeshInstance3D
var slice_materials=[]
var shadow:DirectionalLight3D
var warm_room_key:OmniLight3D
var cool_room_fill:OmniLight3D
var sfx={}
var particles=[]
var hud_script=preload("res://scripts/house_hud.gd")

func _ready():
 add_to_group("mobile_games")
 if FileAccess.file_exists("res://assets/data/floor_surfaces.json"):
  var parsed=JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/floor_surfaces.json"))
  if parsed is Dictionary:floor_data=parsed
 actor_source=MODEL.instantiate();add_child(actor_source)
 environment_root=actor_source.find_child("TwoStoreyHouse",true,false)
 var source_hero=actor_source.find_child("TricksterCharacter",true,false)
 var source_neighbor=actor_source.find_child("NeighborCharacter",true,false)
 hero=source_hero.duplicate();add_child(hero);hero.position=Vector3.ZERO;hero.rotation=Vector3.ZERO
 neighbor=source_neighbor.duplicate();add_child(neighbor);neighbor.position=Vector3.ZERO;neighbor.rotation=Vector3.ZERO
 source_hero.hide();source_neighbor.hide()
 hero_contact=make_contact(Vector2(.78,.54));neighbor_contact=make_contact(Vector2(1.02,.72))
 attach_animations(hero,"TricksterCharacter");attach_animations(neighbor,"NeighborCharacter")
 for c in actor_source.find_children("*","Camera3D",true,false):c.current=false
 for light in actor_source.find_children("*","Light3D",true,false):light.visible=false
 make_slices(environment_root)
 for f in range(2):navs.append(build_nav(f))
 camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=10.2;add_child(camera);camera.current=true
 shadow=DirectionalLight3D.new();shadow.rotation_degrees=Vector3(-55,-25,0);shadow.light_color=Color("fff4e5");shadow.light_energy=.22;shadow.shadow_enabled=true;shadow.directional_shadow_max_distance=32;add_child(shadow)
 var env=WorldEnvironment.new();var e=Environment.new();e.background_mode=Environment.BG_COLOR;e.background_color=Color("202a2e");e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color=Color("d1e0e4");e.ambient_light_energy=.38;e.tonemap_mode=Environment.TONE_MAPPER_FILMIC;env.environment=e;add_child(env)
 # Two unshadowed local practical lights add depth to faces and the furnished rooms.
 # These keep the Web Compatibility renderer usable on mobile Safari.
 warm_room_key=OmniLight3D.new();warm_room_key.name="WarmRoomKey"
 warm_room_key.position=Vector3(-2.9,3.0,3.2)
 warm_room_key.light_color=Color("ffdfbb");warm_room_key.light_energy=.48
 warm_room_key.omni_range=11.0;warm_room_key.omni_attenuation=1.8
 warm_room_key.shadow_enabled=false;add_child(warm_room_key)
 cool_room_fill=OmniLight3D.new();cool_room_fill.name="CoolRoomFill"
 cool_room_fill.position=Vector3(3.5,3.6,-1.2)
 cool_room_fill.light_color=Color("d0e4f5");cool_room_fill.light_energy=.19
 cool_room_fill.omni_range=9.5;cool_room_fill.omni_attenuation=1.8
 cool_room_fill.shadow_enabled=false;add_child(cool_room_fill)
 var canvas=CanvasLayer.new();add_child(canvas);hud=hud_script.new();hud.game=self;canvas.add_child(hud)
 for k in ["pickup","arm","prank","caught","victory"]:
  var p=AudioStreamPlayer.new();p.stream=load("res://assets/sfx/%s.wav"%k);p.bus="SFX";add_child(p);sfx[k]=p
 start_case(index)
 var cfg=ConfigFile.new();cfg.load("user://pakosti_release.cfg");set_quality(bool(cfg.get_value("graphics","detail",not (OS.has_feature("web") or OS.has_feature("mobile")))))

func floor_height(p:Vector2,f:int)->float:
 if floor_data.is_empty():return .20+f*H
 var w=int(floor_data.width);var d=int(floor_data.depth);var cell_size=float(floor_data.cell)
 var u=clampf((p.x-float(floor_data.origin[0]))/cell_size,0,w-1.001);var v=clampf((p.y-float(floor_data.origin[1]))/cell_size,0,d-1.001)
 var x=int(floor(u));var z=int(floor(v));var values=floor_data.floors[clampi(f,0,1)]
 var a=lerpf(float(values[z*w+x]),float(values[z*w+x+1]),u-x)
 var b=lerpf(float(values[(z+1)*w+x]),float(values[(z+1)*w+x+1]),u-x)
 return lerpf(a,b,v-z)
func make_contact(dimensions:Vector2)->MeshInstance3D:
 var contact=MeshInstance3D.new();contact.name="SoftContactShadow";var mesh=PlaneMesh.new();mesh.size=dimensions;contact.mesh=mesh
 var material=ShaderMaterial.new();material.shader=CONTACT_SHADER;contact.material_override=material;contact.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(contact);return contact
func update_contact(contact:MeshInstance3D,actor:Node3D,p:Vector2,f:int,shown:bool):
 contact.visible=shown
 contact.position=Vector3(p.x,floor_height(p,f)+.004,p.y);contact.rotation.y=actor.rotation.y

func make_slices(node:Node):
 if node is MeshInstance3D:
  for i in range(node.mesh.get_surface_count()):
   var m=node.get_active_material(i)
   if not m is StandardMaterial3D:continue
   var sm=ShaderMaterial.new();sm.shader=CUTAWAY_SHADER
   sm.set_shader_parameter("tint",m.albedo_color);sm.set_shader_parameter("rough",m.roughness);sm.set_shader_parameter("metal",m.metallic)
   if m.albedo_texture:sm.set_shader_parameter("tex",m.albedo_texture);sm.set_shader_parameter("textured",true)
   if m.normal_enabled and m.normal_texture:
    sm.set_shader_parameter("normal_tex",m.normal_texture);sm.set_shader_parameter("normal_mapped",true);sm.set_shader_parameter("normal_scale",m.normal_scale)
   if m.roughness_texture:
    sm.set_shader_parameter("rough_tex",m.roughness_texture);sm.set_shader_parameter("rough_mapped",true);sm.set_shader_parameter("rough_channel",m.roughness_texture_channel)
   if m.ao_enabled and m.ao_texture:
    sm.set_shader_parameter("ao_tex",m.ao_texture);sm.set_shader_parameter("ao_mapped",true)
   node.set_surface_override_material(i,sm);slice_materials.append(sm)
 for c in node.get_children():make_slices(c)

func set_slice():
 # Dollhouse view: show BOTH existing floors at all times.
 for m in slice_materials:m.set_shader_parameter("cutoff",99.0)

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
 paused=false;pending_target=Vector2.INF;pending_action="";escape_ready=false;escape_route=false;index=clampi(n,0,CASES.size()-1);floor_id=0;neighbor_floor=int(CASES[index].floor);player_pos=Vector2(4.2,1.1);neighbor_pos=Vector2(-4.1,1.1)
 for particle in particles:
  if is_instance_valid(particle.node):particle.node.queue_free()
 particles.clear()
 for t in targets:t.node.queue_free()
 for t in supplies:t.node.queue_free()
 targets.clear();supplies.clear();if is_instance_valid(exit_marker):exit_marker.queue_free()
 inventory=[0,0,0,0,0,0,0,0];lives=3;caught=0;elapsed=0;action_time=0;stick=Vector2.ZERO;hidden=false;reaction=0;anger=0;anger_events=0;bonus_awarded=false;combo=0;best_combo=0;combo_timer=0;capture_time=0;safe_time=4;alert=0;climbing=0;state="playing";player_path.clear();enemy_path.clear();enemy_climbing=0;enemy_search_time=0;waypoint=1
 var tasks:Array=CASES[index].tasks
 for i in range(tasks.size()):
  var data:Array=tasks[i]
  var kind=int(data[0])
  var p:Vector2=TRAP_SPOTS[int(data[1])]
  var trap_title=String(data[2])
  var marker=make_marker(p,neighbor_floor,kind,false,trap_title)
  targets.append({"kind":kind,"pos":p,"floor":neighbor_floor,"armed":false,"used":false,"node":marker,"label":trap_title,"order":i})
  var supply_pos=SUPPLY_SPOTS[i]
  var supply=make_marker(supply_pos,0,kind,true,NAMES[kind])
  supplies.append({"kind":kind,"pos":supply_pos,"floor":0,"taken":false,"node":supply})
 exit_marker=make_exit_marker();exit_marker.hide()
 set_slice();update_prank_labels();hud.refresh()
func make_marker(p:Vector2,f:int,kind:int,supply:bool,custom_title:String="")->Node3D:
 var n=Node3D.new();n.position=Vector3(p.x,floor_height(p,f)+.04,p.y);add_child(n)
 var mesh=MeshInstance3D.new();var ring=TorusMesh.new();ring.inner_radius=.28;ring.outer_radius=.32;ring.rings=20;ring.ring_segments=8;mesh.mesh=ring
 var m=StandardMaterial3D.new();m.albedo_color=COLORS[kind];m.emission_enabled=true;m.emission=COLORS[kind];m.emission_energy_multiplier=.25;mesh.material_override=m;n.add_child(mesh)
 var label=Label3D.new();label.text=("ВЗЯТЬ: " if supply else "")+(custom_title if not custom_title.is_empty() else NAMES[kind]);label.font_size=22;label.pixel_size=.009;label.position.y=.58;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.no_depth_test=false;n.add_child(label)
 if supply:
  var icon=MeshInstance3D.new();var sphere=SphereMesh.new();sphere.radius=.12;sphere.height=.24;icon.mesh=sphere;icon.material_override=m;icon.position.y=.2;n.add_child(icon)
 return n
func update_prank_labels():
 for item in targets+supplies:
  if not is_instance_valid(item.node):continue
  var still_active=not bool(item.get("used",false)) and not bool(item.get("taken",false))
  if item.has("armed") and item.armed:still_active=false
  item.node.visible=still_active and item.floor==floor_id
  for child in item.node.get_children():
   if child is Label3D:child.visible=item.node.visible and player_pos.distance_to(item.pos)<2.6
func make_exit_marker()->Node3D:
 var n=Node3D.new();n.name="SafeExit";n.position=Vector3(EXIT_POS.x,floor_height(EXIT_POS,0)+.05,EXIT_POS.y);add_child(n)
 var mesh=MeshInstance3D.new();var ring=TorusMesh.new();ring.inner_radius=.37;ring.outer_radius=.45;mesh.mesh=ring
 var m=StandardMaterial3D.new();m.albedo_color=Color("8ae0ac");m.emission_enabled=true;m.emission=Color("2c9d70");m.emission_energy_multiplier=.35;mesh.material_override=m;n.add_child(mesh)
 var label=Label3D.new();label.text="ВЫХОД";label.font_size=40;label.pixel_size=.008;label.position.y=.75;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;n.add_child(label)
 return n
func walk_to(p:Vector2,kind:String):
 if paused or state!="playing" or climbing>0:return
 hidden=false;pending_target=p;pending_action=kind;player_path=path(player_pos,p,floor_id)
 if player_pos.distance_to(p)<.8:complete_walk_action()
func complete_walk_action():
 var kind=pending_action;pending_action="";pending_target=Vector2.INF;player_path.clear()
 match kind:
  "interact":act()
  "stairs":
   if near_stair():start_climb()
  "hide":
   if near_hide():act()
  "exit":finish_escape()
func guide_to_exit():
 if not escape_ready or paused or state!="playing":return
 escape_route=true
 if floor_id==1:walk_to(Vector2(5.0,-2.15),"stairs")
 else:walk_to(EXIT_POS,"exit")
func bonus_description()->String:
 var rule=String(CASES[index].bonus_rule)
 if rule=="clean":return "Без поимок"
 if rule=="fast":return "Успеть за %d секунд"%int(CASES[index].par)
 if rule.begins_with("combo"):return "Серия из %s реакций"%rule.trim_prefix("combo")
 return "Завершить миссию"
func qualifies_bonus()->bool:
 var rule=String(CASES[index].bonus_rule)
 if rule=="clean":return caught==0
 if rule=="fast":return elapsed<=float(CASES[index].par)
 if rule.begins_with("combo"):return best_combo>=int(rule.trim_prefix("combo"))
 return false
func finish_escape():
 if not escape_ready or state!="playing" or floor_id!=0 or player_pos.distance_to(EXIT_POS)>.9:return
 state="won";escape_route=false;bonus_awarded=qualifies_bonus();play("victory")
 var cfg=ConfigFile.new();cfg.load("user://pakosti_release.cfg")
 var next_case=mini(index+1,CASES.size()-1)
 var unlocked=maxi(int(cfg.get_value("house","unlocked",0)),next_case)
 cfg.set_value("house","unlocked",unlocked);cfg.set_value("house","last",next_case)
 cfg.set_value("scores",str(index),maxi(int(cfg.get_value("scores",str(index),0)),maxi(100,1000-int(elapsed)*2-caught*150+best_combo*120+anger_events*60+(300 if bonus_awarded else 0))))
 cfg.save("user://pakosti_release.cfg");hud.show_result(true)
func hint()->String:
 if escape_ready:return "К ВЫХОДУ"
 if climbing>0:return "ЛЕСТНИЦА"
 if hidden:return "ВЫЙТИ ИЗ УКРЫТИЯ"
 for s in supplies:
  if not s.taken and floor_id==s.floor and player_pos.distance_to(s.pos)<.95:return "ВЗЯТЬ: "+NAMES[s.kind]
 for t in targets:
  if not t.used and not t.armed and floor_id==t.floor and player_pos.distance_to(t.pos)<.95:return ("УСТАНОВИТЬ: " if inventory[t.kind]>0 else "НАЙДИ: ")+t.label
 if near_stair():return "ПОДНЯТЬСЯ" if floor_id==0 else "СПУСТИТЬСЯ"
 if near_hide():return "СПРЯТАТЬСЯ"
 return "ДЕЙСТВИЕ"
func near_stair()->bool:
 return player_pos.distance_to(Vector2(6.7,1.8) if floor_id==0 else Vector2(5.0,-2.15))<1.1
func near_hide()->bool:return player_pos.distance_to(Vector2(-7.1,1.5))<1 or player_pos.distance_to(Vector2(3.25,2.5))<1
func act():
 if paused or state!="playing" or climbing>0:return
 if hidden:hidden=false;return
 for s in supplies:
  if not s.taken and floor_id==s.floor and player_pos.distance_to(s.pos)<.95:
   s.taken=true;s.node.hide();inventory[s.kind]+=1;play("pickup");action_time=.55;return
 for t in targets:
  if not t.used and not t.armed and floor_id==t.floor and player_pos.distance_to(t.pos)<.95:
   if inventory[t.kind]>0:t.armed=true;inventory[t.kind]-=1;play("arm");action_time=.8
   return
 if near_stair():start_climb();return
 if near_hide():hidden=true;player_path.clear()
func start_climb():
 climbing=3.1;climb_from=floor_id;climb_to=1-floor_id;climb_start=player_pos;climb_end=Vector2(5.0,-2.15) if floor_id==0 else Vector2(6.7,1.8);hidden=false;player_path.clear();set_slice()
func finish_prank(t):
 t.used=true;t.armed=false;t.node.hide();reaction=2.5;reaction_kind=t.kind;play("prank")
 anger_events+=1;anger=clampf(anger+.14+float(index)*.002,0,1)
 combo=combo+1 if combo_timer>0 else 1
 best_combo=maxi(best_combo,combo);combo_timer=10.0
 alert=maxf(alert,.25+anger*.25);enemy_path.clear()
 for i in range(14):
  var p=MeshInstance3D.new();var mesh=SphereMesh.new();mesh.radius=.04;mesh.height=.08;p.mesh=mesh
  var m=StandardMaterial3D.new();m.albedo_color=COLORS[t.kind];p.material_override=m;p.position=Vector3(t.pos.x,.8+t.floor*H,t.pos.y);add_child(p);particles.append({"node":p,"velocity":Vector3(randf_range(-1.5,1.5),randf_range(1.2,2.5),randf_range(-1.5,1.5)),"life":1.5})
 if targets.all(func(item):return item.used):
  escape_ready=true;exit_marker.show();hud.refresh()
func play(k:String):sfx[k].play()
func begin_capture():
 if capture_time>0 or safe_time>0 or state!="playing":return
 capture_time=1.8;lives-=1;caught+=1;play("caught")
 player_path.clear();pending_target=Vector2.INF;pending_action="";escape_route=false;hidden=false
 alert=1.0
func tick_capture(dt:float):
 capture_time=maxf(0,capture_time-dt)
 var phase=1.8-capture_time
 animate(hero,0,101);animate(neighbor,0,102)
 # Keep whole-body tilt neutral; the skeleton handles recoil and restraint.
 hero.rotation.z=0
 neighbor.rotation.z=0
 var arm=neighbor.find_child("Arm_R*",true,false)
 if arm is Node3D and not neighbor.has_meta("animation_player"):arm.rotation.z=sin(phase*17.0)*.25
 if capture_time<=0:
  hero.rotation.z=0;neighbor.rotation.z=0
  player_pos=EXIT_POS;floor_id=0;safe_time=5.5;alert=0;enemy_path.clear();set_slice()
  if lives<=0:state="lost";hud.show_result(false)
func begin_neighbor_stairs():
 if enemy_climbing>0 or enemy_search_time<=0:return
 enemy_climb_from=neighbor_floor;enemy_climb_to=floor_id
 enemy_climb_start=neighbor_pos
 enemy_climb_end=Vector2(5.0,-2.15) if enemy_climb_from==0 else Vector2(6.7,1.8)
 enemy_climbing=3.1;enemy_path.clear()
func update_neighbor_stairs(dt:float):
 enemy_climbing=maxf(0,enemy_climbing-dt)
 var progress=1.0-enemy_climbing/3.1
 var bottom=STAIR_BOTTOM;var top=STAIR_TOP
 var entry=bottom if enemy_climb_from==0 else top
 var landing=top if enemy_climb_from==0 else bottom
 var p:Vector2;var height:float
 if progress<.18:
  p=enemy_climb_start.lerp(entry,progress/.18);height=enemy_climb_from*H
 elif progress<.82:
  var portion=(progress-.18)/.64
  p=entry.lerp(landing,portion);height=lerpf(enemy_climb_from*H,enemy_climb_to*H,portion)
 else:
  p=landing.lerp(enemy_climb_end,(progress-.82)/.18);height=enemy_climb_to*H
 enemy_stair_world=Vector3(p.x,.2+height,p.y)
 if enemy_climbing<=0:
  neighbor_floor=enemy_climb_to;neighbor_pos=enemy_climb_end
  enemy_path.clear();enemy_search_time=maxf(enemy_search_time,2.0)
func tick_enemy(dt:float):
 enemy_search_time=maxf(0,enemy_search_time-dt)
 if enemy_climbing>0:
  update_neighbor_stairs(dt)
  return
 if reaction>0:
  reaction=maxf(0,reaction-dt);return
 var diff=player_pos-neighbor_pos
 var can_see=floor_id==neighbor_floor and not hidden and climbing<=0 and safe_time<=0 and diff.length()<3.1+anger*1.5 and diff.normalized().dot(face)>-.1 and clear_line(neighbor_pos,player_pos,neighbor_floor)
 if can_see:enemy_search_time=maxf(enemy_search_time,6.0+anger*3.0)
 alert=clampf(alert+dt*((1.1+anger*.65+float(CASES[index].difficulty)*.09) if can_see else -.5),0,1)
 var pursue_stairs=enemy_search_time>0 and floor_id!=neighbor_floor
 var stair_entry=Vector2(6.7,1.8) if neighbor_floor==0 else Vector2(5.0,-2.15)
 var dest:Vector2=stair_entry if pursue_stairs else (player_pos if alert>.85 and floor_id==neighbor_floor else route[waypoint])
 if neighbor_pos.distance_to(dest)<.50 and pursue_stairs:
  begin_neighbor_stairs();return
 if neighbor_pos.distance_to(dest)<.15 and alert<=.85 and not pursue_stairs:
  waypoint=(waypoint+1)%route.size();dest=route[waypoint]
 if enemy_path.is_empty() or (alert>.85 and int(elapsed*4)%3==0):
  enemy_path=path(neighbor_pos,dest,neighbor_floor)
 while not enemy_path.is_empty() and neighbor_pos.distance_to(enemy_path[0])<.055:enemy_path.remove_at(0)
 if not enemy_path.is_empty():
  var step=enemy_path[0]-neighbor_pos
  face=step.normalized()
  var speed=(2.3+anger*1.35+float(CASES[index].difficulty)*.12) if alert>.85 else (1.15+anger*.75+float(CASES[index].difficulty)*.10)
  neighbor_pos+=step.limit_length(dt*speed)
 for trap in targets:
  if trap.armed and not trap.used and neighbor_floor==trap.floor and neighbor_pos.distance_to(trap.pos)<.45:finish_prank(trap);return
 if can_see and diff.length()<.62:begin_capture()
func clear_line(a:Vector2,b:Vector2,f:int)->bool:
 for i in range(1,15):
  if blocked(a.lerp(b,float(i)/15),f):return false
 return true
func _process(dt:float):
 if paused:return
 # Keep soft accent lighting on the currently visible house floor, including
 # when the character uses the stairway. No extra dynamic shadows on iPhone.
 if is_instance_valid(warm_room_key):
  warm_room_key.position.y=3.0+floor_id*H
 if is_instance_valid(cool_room_fill):
  cool_room_fill.position.y=3.6+floor_id*H
 if state=="won":animate(hero,0,99)
 elapsed+=dt;safe_time=maxf(0,safe_time-dt);action_time=maxf(0,action_time-dt);combo_timer=maxf(0,combo_timer-dt)
 if combo_timer<=0:combo=0
 if capture_time>0:
  tick_capture(dt);hud.refresh();return
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
   if climbing<=0:
    floor_id=climb_to;player_pos=climb_end;set_slice()
    if escape_route:guide_to_exit()
  else:move_player(dt)
  tick_enemy(dt)
 neighbor.position=enemy_stair_world if enemy_climbing>0 else Vector3(neighbor_pos.x,floor_height(neighbor_pos,neighbor_floor)-.015,neighbor_pos.y)
 neighbor.rotation.y=atan2(face.x,face.y);animate(neighbor,0 if reaction>0 else 1,reaction_kind+1 if reaction>0 else 0)
 hero.visible=not hidden;neighbor.visible=neighbor_floor==floor_id or climbing>0 or enemy_climbing>0
 update_contact(hero_contact,hero,player_pos,floor_id,not hidden and climbing<=0)
 update_contact(neighbor_contact,neighbor,neighbor_pos,neighbor_floor,neighbor.visible and enemy_climbing<=0)
 var focus=hero.position+Vector3(0,.8,0);var target=Vector3(clampf(focus.x,-3,3),H*.65,0)
 camera.position=target+Vector3(1.2,7.5,17);camera.look_at(target)
 for i in range(particles.size()-1,-1,-1):
  var p=particles[i];p.life-=dt;p.node.position+=p.velocity*dt;p.velocity.y-=dt*4
  if p.life<=0:p.node.queue_free();particles.remove_at(i)
 fps_time+=dt;fps_frames+=1
 if fps_time>4 and quality:
  if fps_frames/fps_time<25:set_quality(false)
  fps_time=0;fps_frames=0
 update_prank_labels();hud.refresh()
func move_player(dt:float):
 var input=Input.get_vector("ui_left","ui_right","ui_up","ui_down")+stick
 if Input.is_key_pressed(KEY_A):input.x-=1
 if Input.is_key_pressed(KEY_D):input.x+=1
 if Input.is_key_pressed(KEY_W):input.y-=1
 if Input.is_key_pressed(KEY_S):input.y+=1
 input=input.limit_length(1);var motion=Vector2.ZERO
 if input.length()>.1:
  player_path.clear();pending_target=Vector2.INF;pending_action="";escape_route=false;motion=input;hidden=false
 elif not player_path.is_empty():
  while not player_path.is_empty() and player_pos.distance_to(player_path[0])<.055:player_path.remove_at(0)
  if not player_path.is_empty():motion=(player_path[0]-player_pos).normalized()
 if not hidden and action_time<=0:
  var step=motion*SPEED*dt
  for axis in [Vector2(step.x,0),Vector2(0,step.y)]:
   if not blocked(player_pos+axis,floor_id):player_pos+=axis
 hero.position=Vector3(player_pos.x,floor_height(player_pos,floor_id)-.015*hero.scale.y,player_pos.y)
 if motion.length()>.1:hero.rotation.y=lerp_angle(hero.rotation.y,atan2(motion.x,motion.y),minf(1,dt*12))
 animate(hero,motion.length() if action_time<=0 else 0,-1 if action_time>0 else 0)
 if pending_target!=Vector2.INF and player_pos.distance_to(pending_target)<.8:complete_walk_action()
 if escape_ready and escape_route and floor_id==0 and player_pos.distance_to(EXIT_POS)<.8:finish_escape()
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
  # The source import stores both actors in one glTF animation library.
  if name=="catch" and source_name!="NeighborCharacter":continue
  if name=="caught_react" and source_name!="TricksterCharacter":continue
  animation.loop_mode=Animation.LOOP_LINEAR if name in ["idle","walk","sneak","run"] else Animation.LOOP_NONE
  library.add_animation(name,animation)
 player.add_animation_library("",library)
 actor.set_meta("animation_player",player)
func animate(actor:Node3D,speed:float,pose:int):
 if actor.has_meta("animation_player"):
  var player:AnimationPlayer=actor.get_meta("animation_player")
  var clip="walk" if speed>.1 else "idle"
  if pose==99:clip="celebrate"
  elif pose==101:clip="caught_react" if actor==hero else "idle"
  elif pose==102:clip="catch" if actor==neighbor else "idle"
  elif pose==-1:clip="plant_trap"
  elif pose in [1,3]:clip="react_slip"
  elif pose>0:clip="react_surprise"
  if player.has_animation(clip) and player.current_animation!=clip:player.play(clip,.16)
  player.speed_scale=maxf(.65,speed) if clip=="walk" else 1.0
 preload("res://scripts/cast_expressions.gd").apply(actor,elapsed,actor==neighbor,pose==99,anger if actor==neighbor else 0.0)
 actor.rotation.z=sin(elapsed*12)*.12 if pose in [1,3] else 0
func set_quality(enabled:bool):
 quality=enabled;shadow.shadow_enabled=enabled;get_viewport().scaling_3d_scale=1 if enabled else .75
 # Smooth mode uses lower-cost unshadowed local lighting; detailed mode retains depth.
 if is_instance_valid(warm_room_key):warm_room_key.light_energy=.48 if enabled else .32
 if is_instance_valid(cool_room_fill):cool_room_fill.light_energy=.19 if enabled else .11
 get_viewport().msaa_3d=Viewport.MSAA_2X if enabled else Viewport.MSAA_DISABLED
 for sm in slice_materials:sm.set_shader_parameter("detail_normals",enabled)
 var cfg=ConfigFile.new();cfg.load("user://pakosti_release.cfg");cfg.set_value("graphics","detail",enabled);cfg.save("user://pakosti_release.cfg")
func click_world(p:Vector2):
 if paused or state!="playing" or climbing>0:return
 if hidden:hidden=false
 var closest=68.0;var selected=Vector2.INF
 for item in supplies+targets:
  if item.floor!=floor_id or (item.has("taken") and item.taken) or (item.has("used") and (item.used or item.armed)):continue
  var screen=camera.unproject_position(Vector3(item.pos.x,.55+floor_id*H,item.pos.y))
  var distance=screen.distance_to(p)
  if distance<closest:closest=distance;selected=item.pos
 if selected!=Vector2.INF:
  escape_route=false;walk_to(selected,"interact");return
 if escape_ready and floor_id==0:
  var exit_screen=camera.unproject_position(Vector3(EXIT_POS.x,.6,EXIT_POS.y))
  if exit_screen.distance_to(p)<80:guide_to_exit();return
 var stair_pos=Vector2(6.7,1.8) if floor_id==0 else Vector2(5.0,-2.15)
 var stair_screen=camera.unproject_position(Vector3(stair_pos.x,.5+floor_id*H,stair_pos.y))
 if stair_screen.distance_to(p)<70:
  escape_route=false;walk_to(stair_pos,"stairs");return
 for hide_pos in [Vector2(-7.1,1.5),Vector2(3.25,2.5)]:
  var hide_screen=camera.unproject_position(Vector3(hide_pos.x,.7+floor_id*H,hide_pos.y))
  if hide_screen.distance_to(p)<55:
   escape_route=false;walk_to(hide_pos,"hide");return
 var origin=camera.project_ray_origin(p)
 var direction=camera.project_ray_normal(p)
 var hit=Plane(Vector3.UP,.2+floor_id*H).intersects_ray(origin,direction)
 if hit==null:return
 var target=Vector2(clampf(hit.x,-7.45,7.45),clampf(hit.z,-2.70,2.70))
 escape_route=false;pending_action="";pending_target=Vector2.INF
 player_path=path(player_pos,target,floor_id)
func _unhandled_input(e):
 if capture_time>0:return
 if paused:
  if e is InputEventKey and e.pressed and e.keycode==KEY_ESCAPE and is_instance_valid(hud.pause_panel):hud.pause_panel.queue_free();hud.pause_panel=null;set_paused(false)
  return
 if e is InputEventScreenTouch and e.pressed:
  if e.position.y>92:
   click_world(e.position);get_viewport().set_input_as_handled()
 elif e is InputEventMouseButton and e.button_index==MOUSE_BUTTON_LEFT and e.pressed:
  if e.position.y>92:
   click_world(e.position);get_viewport().set_input_as_handled()
 elif e is InputEventKey and e.pressed and not e.echo:
  if e.keycode in [KEY_E,KEY_SPACE]:act()
  elif e.keycode==KEY_ESCAPE:hud.show_pause()
  elif e.keycode==KEY_Q:set_quality(not quality)
func set_paused(value:bool):
 paused=value;stick=Vector2.ZERO;stick_id=-100;player_path.clear();pending_target=Vector2.INF;pending_action="";escape_route=false
 for actor in [hero,neighbor]:
  if actor.has_meta("animation_player"):actor.get_meta("animation_player").speed_scale=0 if value else 1
func _notification(what):
 if what==NOTIFICATION_APPLICATION_FOCUS_OUT:
  set_paused(true)
  if is_instance_valid(hud):hud.show_pause()

func _exit_tree():
 for player in sfx.values():
  if is_instance_valid(player):player.stop()
