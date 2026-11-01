extends Control
const SAVE="user://pakosti_release.cfg"
var active_game:Node
var panel:Control
var music:AudioStreamPlayer
var modal:Control
var settings=ConfigFile.new()
var music_level=.55
var sfx_level=.75
var continue_button:Button
var quality=true
func _ready():
 settings.load(SAVE);music_level=clampf(float(settings.get_value("audio","music",.55)),0,1);sfx_level=clampf(float(settings.get_value("audio","sfx",.75)),0,1)
 for name in ["Music","SFX"]:
  if AudioServer.get_bus_index(name)<0:AudioServer.add_bus();AudioServer.set_bus_name(AudioServer.bus_count-1,name)
 apply_audio()
 music=AudioStreamPlayer.new();music.bus="Music";music.stream=load("res://assets/music/menu_theme.mp3");music.stream.loop=true;add_child(music)
 panel=Control.new();panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(panel)
 var art=TextureRect.new();art.texture=load("res://assets/menu/background.webp");art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;art.mouse_filter=Control.MOUSE_FILTER_IGNORE;panel.add_child(art)
 var backdrop=ColorRect.new();backdrop.name="MenuShade";backdrop.color=Color(.035,.065,.075,1);backdrop.mouse_filter=Control.MOUSE_FILTER_IGNORE;panel.add_child(backdrop)
 var title=Label.new();title.name="GameTitle";title.text="ПАКОСТИ
ПО СОСЕДСТВУ";title.add_theme_font_size_override("font_size",46);title.modulate=Color("f6cc78");panel.add_child(title)
 var subtitle=Label.new();subtitle.name="Subtitle";subtitle.text="Планируй. Прячься. Удивляй.";subtitle.add_theme_font_size_override("font_size",20);subtitle.modulate=Color("c4d5ce");panel.add_child(subtitle)
 continue_button=mobile_button("ИГРАТЬ",func():menu_action(0));continue_button.name="Play"
 var cases=mobile_button("ЗАДАНИЯ",func():menu_action(2));cases.name="Cases"
 var options=mobile_button("НАСТРОЙКИ",func():menu_action(3));options.name="Options"
 var full=mobile_button("ЭКРАН",func():preload("res://scripts/mobile_shell.gd").request_fullscreen());full.name="Fullscreen";full.add_theme_font_size_override("font_size",16)
 var caption=Label.new();caption.name="BuildCaption";caption.text="ТЕСТОВАЯ СБОРКА  /  8 ИСПЫТАНИЙ";caption.add_theme_font_size_override("font_size",16);caption.modulate=Color("a5bbb6");panel.add_child(caption)
 layout_menu()
func mobile_button(text:String,callback:Callable)->Button:
 var b=Button.new();b.text=text;b.focus_mode=Control.FOCUS_NONE;b.add_theme_font_size_override("font_size",24)
 for state in ["normal","hover","pressed"]:
  var style=StyleBoxFlat.new();style.bg_color=Color("344c4e") if state!="pressed" else Color("5f6951");style.border_color=Color("d3ad69");style.set_border_width_all(2);style.set_corner_radius_all(18);b.add_theme_stylebox_override(state,style)
 b.pressed.connect(callback);panel.add_child(b);return b
func layout_menu():
 if not is_instance_valid(panel):return
 var size=get_viewport_rect().size;var safe=64.0 if size.x/size.y>1.9 else 28.0;var x=safe+24
 panel.get_node("MenuShade").size=Vector2(x+420,size.y)
 panel.get_node("GameTitle").position=Vector2(x,30)
 panel.get_node("Subtitle").position=Vector2(x,165)
 continue_button.position=Vector2(x,224);continue_button.size=Vector2(360,90)
 panel.get_node("Cases").position=Vector2(x,332);panel.get_node("Cases").size=Vector2(174,76)
 panel.get_node("Options").position=Vector2(x+186,332);panel.get_node("Options").size=Vector2(174,76)
 panel.get_node("Fullscreen").position=Vector2(size.x-safe-100,22);panel.get_node("Fullscreen").size=Vector2(100,68)
 panel.get_node("BuildCaption").position=Vector2(x,size.y-53)
 if is_instance_valid(modal):
  var p=modal.get_node_or_null("Dialog")
  if p:p.position=(size-p.size)*.5
func menu_action(i:int):
 ensure_music()
 match i:
  0:start_house(int(settings.get_value("house","last",0)))
  1:start_house(0)
  2:open_cases()
  3:open_settings()
func ensure_music():
 if not music.playing:music.play()
func apply_audio():
 for item in [["Music",music_level],["SFX",sfx_level]]:
  var bus=AudioServer.get_bus_index(item[0]);AudioServer.set_bus_volume_db(bus,linear_to_db(maxf(float(item[1]),.0001)));AudioServer.set_bus_mute(bus,float(item[1])<.001)
func save_settings():
 settings.set_value("audio","music",music_level);settings.set_value("audio","sfx",sfx_level);settings.save(SAVE);apply_audio()
func dismiss():
 if is_instance_valid(modal):modal.queue_free();modal=null
func dialog(title:String)->VBoxContainer:
 dismiss();modal=Control.new();modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);panel.add_child(modal)
 var dim=ColorRect.new();dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);dim.color=Color(0,0,0,.85);modal.add_child(dim)
 var p=PanelContainer.new();p.name="Dialog";p.size=Vector2(700,480);p.position=(get_viewport_rect().size-p.size)*.5;modal.add_child(p)
 var style=StyleBoxFlat.new();style.bg_color=Color("182c31");style.border_color=Color("b89a62");style.set_border_width_all(2);style.set_corner_radius_all(12);style.content_margin_left=24;style.content_margin_right=24;style.content_margin_top=16;style.content_margin_bottom=16;p.add_theme_stylebox_override("panel",style)
 var box=VBoxContainer.new();box.add_theme_constant_override("separation",11);p.add_child(box)
 var l=Label.new();l.text=title;l.modulate=Color("e9ca8b");l.add_theme_font_size_override("font_size",22);box.add_child(l);return box
func close_button(box:VBoxContainer):
 var b=Button.new();b.text="НАЗАД";b.custom_minimum_size.y=68;b.pressed.connect(dismiss);box.add_child(b)
func open_cases():
 settings.load(SAVE);var unlocked=int(settings.get_value("house","unlocked",0));var box=dialog("ВЫБЕРИ ИСПЫТАНИЕ")
 var grid=GridContainer.new();grid.columns=2;grid.add_theme_constant_override("h_separation",10);grid.add_theme_constant_override("v_separation",8);box.add_child(grid)
 for i in range(8):
  var b=Button.new();b.text="%02d  %s"%[i+1,preload("res://scripts/house_game.gd").CASES[i].title];b.disabled=i>unlocked;b.custom_minimum_size=Vector2(318,70);b.add_theme_font_size_override("font_size",18);b.clip_text=true;grid.add_child(b);var selected=i;b.pressed.connect(func():start_house(selected))
 var row=HBoxContainer.new();row.add_theme_constant_override("separation",12);box.add_child(row)
 var classic=Button.new();classic.text="КЛАССИЧЕСКИЕ УРОВНИ";classic.custom_minimum_size=Vector2(318,68);classic.pressed.connect(start_classic);row.add_child(classic)
 var back=Button.new();back.text="НАЗАД";back.custom_minimum_size=Vector2(318,68);back.pressed.connect(dismiss);row.add_child(back)
func open_settings():
 var box=dialog("ЗВУК И УПРАВЛЕНИЕ")
 for i in range(2):
  var l=Label.new();l.text="Музыка" if i==0 else "Эффекты";box.add_child(l)
  var s=HSlider.new();s.min_value=0;s.max_value=1;s.step=.01;s.value=music_level if i==0 else sfx_level;s.custom_minimum_size.y=60;box.add_child(s)
  var k=i;s.value_changed.connect(func(value):
   if k==0:music_level=value
   else:sfx_level=value
   save_settings())
 var help=Label.new();help.text="Стик слева — ходьба. Кнопка справа — действие.\nНажми на предмет, чтобы подойти и подобрать.\nПрогресс сохраняется автоматически.";help.add_theme_font_size_override("font_size",15);box.add_child(help)
 close_button(box)
func start_house(i:int):
 dismiss();ensure_music();settings.load(SAVE);var unlocked=int(settings.get_value("house","unlocked",0));i=clampi(i,0,unlocked);settings.set_value("house","last",i);settings.save(SAVE)
 panel.hide();active_game=load("res://scenes/house.tscn").instantiate();active_game.index=i;get_tree().root.add_child(active_game);active_game.menu_requested.connect(return_menu);music.volume_db=-6
func start_classic():
 dismiss();ensure_music();panel.hide();active_game=load("res://scenes/main_3d.tscn").instantiate();get_tree().root.add_child(active_game);active_game.add_to_group("mobile_games");active_game.start_level(active_game.unlocked)
 for child in active_game.get_children():
  if child is AudioStreamPlayer:child.bus="SFX"
 music.volume_db=-6
func return_menu():
 if is_instance_valid(active_game):
  for player in active_game.find_children("*","AudioStreamPlayer",true,false):player.stop()
  get_tree().root.remove_child(active_game);active_game.queue_free()
 active_game=null;panel.show();settings.load(SAVE);music.volume_db=0;get_viewport().scaling_3d_scale=1;get_viewport().msaa_3d=Viewport.MSAA_DISABLED
func _process(_dt):
 layout_menu()
 if is_instance_valid(active_game) and active_game.get_script()==preload("res://scripts/game_3d.gd") and active_game.state==0:return_menu()
func _notification(what):
 if what==NOTIFICATION_APPLICATION_FOCUS_OUT:
  if is_instance_valid(music):music.stream_paused=true
  if is_instance_valid(active_game):active_game.process_mode=Node.PROCESS_MODE_DISABLED
 elif what==NOTIFICATION_APPLICATION_FOCUS_IN:
  if is_instance_valid(music):music.stream_paused=false
  if is_instance_valid(active_game):active_game.process_mode=Node.PROCESS_MODE_INHERIT

func _input(event):
 if get_viewport_rect().size.y>get_viewport_rect().size.x:return
 if is_instance_valid(panel) and panel.visible:
  var ui=modal if is_instance_valid(modal) else panel
  if preload("res://scripts/touch_ui.gd").handle(ui,event):get_viewport().set_input_as_handled()

func _exit_tree():
 if is_instance_valid(music):music.stop()
