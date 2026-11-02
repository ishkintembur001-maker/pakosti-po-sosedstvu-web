extends Control
const SAVE="user://pakosti_release.cfg"
var active_game:Node
var panel:Control
var music:AudioStreamPlayer
var mission_theme:AudioStreamPlayer
var chase_theme:AudioStreamPlayer
var menu_progress:Label
var decorative_rule:ColorRect
var desktop_card:PanelContainer
var modal:Control
var settings=ConfigFile.new()
var music_level=.55
var sfx_level=.75
var continue_button:Button
var quality=true
func _ready():
 if OS.has_feature("windows"):DisplayServer.window_set_size(Vector2i(1280,720))
 settings.load(SAVE);music_level=clampf(float(settings.get_value("audio","music",.55)),0,1);sfx_level=clampf(float(settings.get_value("audio","sfx",.75)),0,1)
 for name in ["Music","SFX"]:
  if AudioServer.get_bus_index(name)<0:AudioServer.add_bus();AudioServer.set_bus_name(AudioServer.bus_count-1,name)
 apply_audio()
 music=make_music("res://assets/music/menu_jazz.ogg")
 mission_theme=make_music("res://assets/music/mission_sneak.ogg")
 chase_theme=make_music("res://assets/music/mission_chase.ogg")
 mission_theme.volume_db=-60
 chase_theme.volume_db=-60
 music.play()
 panel=Control.new();panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(panel)
 var art=TextureRect.new();art.texture=load("res://assets/menu/background.webp");art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;art.mouse_filter=Control.MOUSE_FILTER_IGNORE;panel.add_child(art)
 var backdrop=ColorRect.new();backdrop.name="MenuShade";backdrop.color=Color(.035,.065,.075,1);backdrop.mouse_filter=Control.MOUSE_FILTER_IGNORE;panel.add_child(backdrop)
 var title=Label.new();title.name="GameTitle";title.text="ПАКОСТИ
ПО СОСЕДСТВУ";title.add_theme_font_size_override("font_size",46);title.modulate=Color("f6cc78");panel.add_child(title)
 var subtitle=Label.new();subtitle.name="Subtitle";subtitle.text="Планируй. Прячься. Удивляй.";subtitle.add_theme_font_size_override("font_size",20);subtitle.modulate=Color("c4d5ce");panel.add_child(subtitle)
 decorative_rule=ColorRect.new();decorative_rule.color=Color("d6b277");decorative_rule.mouse_filter=Control.MOUSE_FILTER_IGNORE;panel.add_child(decorative_rule)
 continue_button=mobile_button("ИГРАТЬ",func():menu_action(0));continue_button.name="Play"
 var cases=mobile_button("ЗАДАНИЯ",func():menu_action(2));cases.name="Cases"
 var options=mobile_button("НАСТРОЙКИ",func():menu_action(3));options.name="Options"
 var caption=Label.new();caption.name="BuildCaption";caption.text="24 МИССИИ  •  WINDOWS / ANDROID / iOS";caption.add_theme_font_size_override("font_size",16);caption.modulate=Color("a5bbb6");panel.add_child(caption)
 menu_progress=Label.new();menu_progress.name="CampaignProgress";menu_progress.add_theme_font_size_override("font_size",17);menu_progress.modulate=Color("e8d1ac");panel.add_child(menu_progress)
 desktop_card=PanelContainer.new();desktop_card.name="DesktopDetails"
 var card_style=StyleBoxFlat.new();card_style.bg_color=Color(.05,.10,.12,.90);card_style.border_color=Color("a98559");card_style.set_border_width_all(2);card_style.set_corner_radius_all(18)
 card_style.content_margin_left=22;card_style.content_margin_top=22;card_style.content_margin_right=22;card_style.content_margin_bottom=22
 desktop_card.add_theme_stylebox_override("panel",card_style);panel.add_child(desktop_card)
 var stack=VBoxContainer.new();stack.add_theme_constant_override("separation",14);desktop_card.add_child(stack)
 for row in [["ПЕРВЫЙ СЕЗОН",16,"dbb47e"],["ДВА ЭТАЖА. ОДИН СОСЕД.",22,"f7e3bf"],["24 миссии • десятки пакостей\nРазгадай маршрут соседа и не попадись.",17,"cad7d3"],["ИГРА МЫШКОЙ\nЩелчок — идти и взаимодействовать.\nВсе меню и пауза — мышкой.",17,"d7ba91"]]:
  var label=Label.new();label.text=row[0];label.add_theme_font_size_override("font_size",row[1]);label.modulate=Color(row[2]);stack.add_child(label)
 refresh_menu_progress()
 layout_menu()
func make_music(file:String)->AudioStreamPlayer:
 var player=AudioStreamPlayer.new();player.stream=load(file);player.bus="Music"
 if player.stream is AudioStreamOggVorbis:player.stream.loop=true
 add_child(player)
 return player
func refresh_menu_progress():
 var cfg=ConfigFile.new();cfg.load(SAVE)
 var finished=0
 for i in range(24):
  if int(cfg.get_value("scores",str(i),0))>0:finished+=1
 menu_progress.text="ПРОГРЕСС: %d / 24   •   %d%%"%[finished,roundi(finished*100.0/24.0)]
func mobile_button(text:String,callback:Callable)->Button:
 var b=Button.new();b.text=text;b.focus_mode=Control.FOCUS_NONE;b.add_theme_font_size_override("font_size",24)
 for state in ["normal","hover","pressed","focus"]:
  var style=StyleBoxFlat.new()
  style.bg_color=Color("ae8a55") if text=="ИГРАТЬ" and state=="normal" else (Color("526968") if state=="hover" else (Color("59604b") if state=="pressed" else Color("263f43")))
  style.border_color=Color("e8c68e") if text=="ИГРАТЬ" or state=="hover" else Color("748f91")
  style.set_border_width_all(2);style.set_corner_radius_all(16)
  b.add_theme_stylebox_override(state,style)
 if text=="ИГРАТЬ":b.add_theme_color_override("font_color",Color("162326"))
 b.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
 b.pressed.connect(callback);panel.add_child(b);return b
func layout_menu():
 if not is_instance_valid(panel):return
 var size=get_viewport_rect().size;var safe=64.0 if size.x/size.y>1.9 else 28.0;var x=safe+24
 panel.get_node("MenuShade").size=Vector2(x+420,size.y)
 panel.get_node("GameTitle").position=Vector2(x,30)
 panel.get_node("Subtitle").position=Vector2(x,165)
 decorative_rule.position=Vector2(x,150);decorative_rule.size=Vector2(260,3)
 continue_button.position=Vector2(x,224);continue_button.size=Vector2(360,84)
 panel.get_node("Cases").position=Vector2(x,326);panel.get_node("Cases").size=Vector2(174,73)
 panel.get_node("Options").position=Vector2(x+186,326);panel.get_node("Options").size=Vector2(174,73)
 menu_progress.position=Vector2(x,414)
 panel.get_node("BuildCaption").position=Vector2(x,size.y-43)
 desktop_card.visible=size.x>=1140
 if desktop_card.visible:
  desktop_card.position=Vector2(size.x-470,maxf(42,size.y*.24))
  desktop_card.size=Vector2(405,295)
  desktop_card.custom_minimum_size=Vector2(405,295)
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
func apply_mission_style(btn:Button,completed:bool,locked:bool):
 for mode in ["normal","hover","pressed","disabled","focus"]:
  var st=StyleBoxFlat.new()
  st.bg_color=Color("16292d") if locked else (Color("374840") if completed else Color("294247"))
  if mode=="hover":st.bg_color=Color("4b615e")
  if mode=="pressed":st.bg_color=Color("6c694e")
  st.border_color=Color("d8bc80") if completed else Color("788e86")
  st.set_border_width_all(1)
  st.set_corner_radius_all(11)
  btn.add_theme_stylebox_override(mode,st)
 btn.add_theme_color_override("font_color",Color("f6e8ce"))
 btn.add_theme_color_override("font_disabled_color",Color("7e918c"))
 btn.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND if not locked else Control.CURSOR_ARROW
func open_cases():
 settings.load(SAVE);var unlocked=int(settings.get_value("house","unlocked",0))
 var mission_count=preload("res://scripts/house_game.gd").CASES.size()
 var completed=0
 for i in range(mission_count):
  if int(settings.get_value("scores",str(i),0))>0:completed+=1
 var box=dialog("КАМПАНИЯ — %d/%d ПРОЙДЕНО"%[completed,mission_count])
 var scroll=ScrollContainer.new();scroll.custom_minimum_size=Vector2(660,290);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;box.add_child(scroll)
 var grid=GridContainer.new();grid.columns=2;grid.add_theme_constant_override("h_separation",10);grid.add_theme_constant_override("v_separation",8);scroll.add_child(grid)
 for i in range(preload("res://scripts/house_game.gd").CASES.size()):
  var b=Button.new()
  var best=int(settings.get_value("scores",str(i),0))
  b.text="%02d  %s%s"%[i+1,preload("res://scripts/house_game.gd").CASES[i].title,(" ✓" if best>0 else "")]
  if best>0:b.text+="\nРЕКОРД: %d"%best
  b.disabled=i>unlocked;b.custom_minimum_size=Vector2(318,65)
  b.add_theme_font_size_override("font_size",15 if best>0 else 18)
  b.clip_text=true;apply_mission_style(b,best>0,i>unlocked);grid.add_child(b)
  var selected=i;b.pressed.connect(func():start_house(selected))
 var back=Button.new();back.text="НАЗАД К ГЛАВНОМУ МЕНЮ";back.custom_minimum_size=Vector2(660,68);back.pressed.connect(dismiss);box.add_child(back)
func open_settings():
 var box=dialog("ЗВУК И УПРАВЛЕНИЕ")
 for i in range(2):
  var l=Label.new();l.text="Музыка" if i==0 else "Эффекты";box.add_child(l)
  var s=HSlider.new();s.min_value=0;s.max_value=1;s.step=.01;s.value=music_level if i==0 else sfx_level;s.custom_minimum_size.y=60;box.add_child(s)
  var k=i;s.value_changed.connect(func(value):
   if k==0:music_level=value
   else:sfx_level=value
   save_settings())
 var help=Label.new()
 help.text="МЫШЬ: щёлкни по полу, предмету, ловушке или лестнице.\nПауза, настройки, выход и выбор задания — мышкой.\nНа телефоне используются касания. Прогресс сохраняется."
 help.add_theme_font_size_override("font_size",15);box.add_child(help)
 close_button(box)
func start_mission_music():
 if not mission_theme.playing:mission_theme.play()
 if not chase_theme.playing:chase_theme.play()
func start_house(i:int):
 if not preload("res://scripts/user_models_integration.gd").available():
  var box=dialog("ОРИГИНАЛЬНЫЕ 3D-МОДЕЛИ НЕ НАЙДЕНЫ")
  var message=Label.new()
  message.text="Сборка заблокирована: вместо наших героев не будут показаны другие.\nТребуются пять GLB в assets/user_models."
  message.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  message.custom_minimum_size=Vector2(640,200)
  box.add_child(message)
  close_button(box)
  return
 dismiss();ensure_music();settings.load(SAVE);var unlocked=int(settings.get_value("house","unlocked",0));i=clampi(i,0,unlocked);settings.set_value("house","last",i);settings.save(SAVE)
 panel.hide();active_game=load("res://scenes/house.tscn").instantiate();active_game.index=i;get_tree().root.add_child(active_game);active_game.menu_requested.connect(return_menu);start_mission_music()
func return_menu():
 if is_instance_valid(active_game):
  for player in active_game.find_children("*","AudioStreamPlayer",true,false):player.stop()
  get_tree().root.remove_child(active_game);active_game.queue_free()
 active_game=null;panel.show();settings.load(SAVE);music.volume_db=0;mission_theme.stop();chase_theme.stop()
 refresh_menu_progress();get_viewport().scaling_3d_scale=1;get_viewport().msaa_3d=Viewport.MSAA_DISABLED
func _process(dt):
 layout_menu()
 if is_instance_valid(active_game):
  music.volume_db=move_toward(music.volume_db,-60.0,dt*52)
  var chase=false
  var duck=0.0
  var halt=false
  if active_game.has_method("tick_enemy"):
   chase=active_game.alert>.74
   duck=-9.0 if active_game.capture_time>0 else 0.0
   halt=active_game.paused
  mission_theme.stream_paused=halt;chase_theme.stream_paused=halt
  mission_theme.volume_db=move_toward(mission_theme.volume_db,(-60.0 if chase else -10.0+duck),dt*25)
  chase_theme.volume_db=move_toward(chase_theme.volume_db,(-12.0+duck if chase else -60.0),dt*25)
 else:music.volume_db=move_toward(music.volume_db,0.0,dt*32)
 if is_instance_valid(active_game) and active_game.get_script()==preload("res://scripts/game_3d.gd") and active_game.state==0:return_menu()
func _notification(what):
 if what==NOTIFICATION_APPLICATION_FOCUS_OUT:
  for player in [music,mission_theme,chase_theme]:
   if is_instance_valid(player):player.stream_paused=true
  if is_instance_valid(active_game):active_game.process_mode=Node.PROCESS_MODE_DISABLED
 elif what==NOTIFICATION_APPLICATION_FOCUS_IN:
  for player in [music,mission_theme,chase_theme]:
   if is_instance_valid(player):player.stream_paused=false
  if is_instance_valid(active_game):active_game.process_mode=Node.PROCESS_MODE_INHERIT

func _input(event):
 if get_viewport_rect().size.y>get_viewport_rect().size.x:return
 if is_instance_valid(panel) and panel.visible:
  var ui=modal if is_instance_valid(modal) else panel
  if preload("res://scripts/touch_ui.gd").handle(ui,event):get_viewport().set_input_as_handled()

func _exit_tree():
 for player in [music,mission_theme,chase_theme]:
  if is_instance_valid(player):player.stop()
