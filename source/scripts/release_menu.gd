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
 var art=TextureRect.new();art.texture=load("res://assets/menu/background.webp");art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_SCALE;art.mouse_filter=Control.MOUSE_FILTER_IGNORE;panel.add_child(art)
 for i in range(4):
  var b=Button.new();b.text=["Продолжить","Новая игра","Выбор задания","Настройки"][i];b.position=Vector2(71,185+i*52.5);b.size=Vector2(257,40)
  for state in ["normal","hover","pressed","focus"]:
   var st=StyleBoxFlat.new();st.bg_color=Color(1,.85,.5,.15) if state=="hover" else Color.TRANSPARENT;st.set_corner_radius_all(6);st.set_border_width_all(2 if state=="focus" else 0);st.border_color=Color("f2cf8e");b.add_theme_stylebox_override(state,st)
  for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:b.add_theme_color_override(state,Color.TRANSPARENT)
  var k=i;b.pressed.connect(func():menu_action(k));panel.add_child(b)
  if i==0:continue_button=b
 var classic=Button.new();classic.text="КЛАССИЧЕСКИЕ 4 УРОВНЯ";classic.position=Vector2(73,417);classic.size=Vector2(255,38);classic.pressed.connect(start_classic);panel.add_child(classic)
 var bar=ColorRect.new();bar.color=Color(.02,.035,.045,.95);bar.position=Vector2(0,512);bar.size=Vector2(960,28);panel.add_child(bar)
 var label=Label.new();label.text="РАБОЧАЯ СБОРКА • 8 ИСПЫТАНИЙ В ДОМЕ + 4 КЛАССИЧЕСКИХ • 24 СЮЖЕТНЫХ ЗАДАНИЯ В РАЗРАБОТКЕ";label.position=Vector2(17,518);label.add_theme_font_size_override("font_size",11);label.modulate=Color("d8c695");panel.add_child(label)
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
 var p=PanelContainer.new();p.position=Vector2(170,52);p.size=Vector2(620,435);modal.add_child(p)
 var style=StyleBoxFlat.new();style.bg_color=Color("182c31");style.border_color=Color("b89a62");style.set_border_width_all(2);style.set_corner_radius_all(12);style.content_margin_left=24;style.content_margin_right=24;style.content_margin_top=16;style.content_margin_bottom=16;p.add_theme_stylebox_override("panel",style)
 var box=VBoxContainer.new();box.add_theme_constant_override("separation",11);p.add_child(box)
 var l=Label.new();l.text=title;l.modulate=Color("e9ca8b");l.add_theme_font_size_override("font_size",22);box.add_child(l);return box
func close_button(box:VBoxContainer):
 var b=Button.new();b.text="НАЗАД";b.custom_minimum_size.y=38;b.pressed.connect(dismiss);box.add_child(b)
func open_cases():
 settings.load(SAVE);var unlocked=int(settings.get_value("house","unlocked",0));var box=dialog("ДВУХЭТАЖНЫЙ ДОМ • 8 ИСПЫТАНИЙ")
 var scroll=ScrollContainer.new();scroll.custom_minimum_size.y=285;box.add_child(scroll);var list=VBoxContainer.new();list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(list)
 for i in range(8):
  var b=Button.new();b.text="%02d  %s%s"%[i+1,preload("res://scripts/house_game.gd").CASES[i].title,"  •  ЗАКРЫТО" if i>unlocked else ""];b.disabled=i>unlocked;b.custom_minimum_size.y=44;list.add_child(b);var selected=i;b.pressed.connect(func():start_house(selected))
 close_button(box)
func open_settings():
 var box=dialog("ЗВУК И УПРАВЛЕНИЕ")
 for i in range(2):
  var l=Label.new();l.text="Музыка" if i==0 else "Эффекты";box.add_child(l)
  var s=HSlider.new();s.min_value=0;s.max_value=1;s.step=.01;s.value=music_level if i==0 else sfx_level;s.custom_minimum_size.y=30;box.add_child(s)
  var k=i;s.value_changed.connect(func(value):
   if k==0:music_level=value
   else:sfx_level=value
   save_settings())
 var help=Label.new();help.text="WASD / стрелки — ходьба • E / пробел — действие\nНа телефоне: левый стик + кнопка действия\nНажатие на пол — пройти к точке • Q — графика\nПрогресс и громкость сохраняются автоматически.";help.add_theme_font_size_override("font_size",15);box.add_child(help)
 close_button(box)
func start_house(i:int):
 dismiss();ensure_music();settings.load(SAVE);var unlocked=int(settings.get_value("house","unlocked",0));i=clampi(i,0,unlocked);settings.set_value("house","last",i);settings.save(SAVE)
 panel.hide();active_game=load("res://scenes/house.tscn").instantiate();active_game.index=i;get_tree().root.add_child(active_game);active_game.menu_requested.connect(return_menu);music.volume_db=-6
func start_classic():
 dismiss();ensure_music();panel.hide();active_game=load("res://scenes/main_3d.tscn").instantiate();get_tree().root.add_child(active_game);active_game.start_level(active_game.unlocked)
 for child in active_game.get_children():
  if child is AudioStreamPlayer:child.bus="SFX"
 music.volume_db=-6
func return_menu():
 if is_instance_valid(active_game):
  for player in active_game.find_children("*","AudioStreamPlayer",true,false):player.stop()
  get_tree().root.remove_child(active_game);active_game.queue_free()
 active_game=null;panel.show();settings.load(SAVE);music.volume_db=0;get_viewport().scaling_3d_scale=1
func _process(_dt):
 if is_instance_valid(active_game) and active_game.get_script()==preload("res://scripts/game_3d.gd") and active_game.state==0:return_menu()
func _notification(what):
 if what==NOTIFICATION_APPLICATION_FOCUS_OUT:
  if is_instance_valid(music):music.stream_paused=true
  if is_instance_valid(active_game):active_game.process_mode=Node.PROCESS_MODE_DISABLED
 elif what==NOTIFICATION_APPLICATION_FOCUS_IN:
  if is_instance_valid(music):music.stream_paused=false
  if is_instance_valid(active_game):active_game.process_mode=Node.PROCESS_MODE_INHERIT

func _input(event):
 if is_instance_valid(panel) and panel.visible:
  var ui=modal if is_instance_valid(modal) else panel
  if preload("res://scripts/touch_ui.gd").handle(ui,event):get_viewport().set_input_as_handled()

func _exit_tree():
 if is_instance_valid(music):music.stop()
