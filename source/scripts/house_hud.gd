extends Control
var game
var top:Label
var objective:Label
var action:Button
var result:PanelContainer
var pause_panel:PanelContainer
var pause_button:Button
var bag:Label
var tip:Label
var strip:ColorRect
var last_size=Vector2.ZERO
func _ready():
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_IGNORE
 strip=ColorRect.new();strip.color=Color(.035,.06,.07,.86);strip.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(strip)
 top=label(24,Color("f4d192"));objective=label(19,Color("d5e0da"));bag=label(21,Color("f2d298"));tip=label(18,Color("d9e4de"));tip.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 pause_button=button("II",Vector2.ZERO,Vector2(76,72),func():show_pause());pause_button.add_theme_font_size_override("font_size",27)
 action=button("ДЕЙСТВИЕ",Vector2.ZERO,Vector2(240,76),func():game.hud_action());action.add_theme_font_size_override("font_size",21);action.hide()
 layout()
func label(font_size:int,tint:Color)->Label:
 var l=Label.new();l.add_theme_font_size_override("font_size",font_size);l.modulate=tint;l.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(l);return l
func button(text:String,pos:Vector2,dimensions:Vector2,callback:Callable)->Button:
 var b=Button.new();b.text=text;b.position=pos;b.size=dimensions;b.focus_mode=Control.FOCUS_NONE
 for state in ["normal","hover","pressed"]:
  var style=StyleBoxFlat.new();style.bg_color=Color("2b464b") if state!="pressed" else Color("5a6550");style.border_color=Color("d2ad69");style.set_border_width_all(2);style.set_corner_radius_all(22);b.add_theme_stylebox_override(state,style)
 b.add_theme_font_size_override("font_size",22);b.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND;b.pressed.connect(callback);add_child(b);return b
func layout():
 var s=get_viewport_rect().size;last_size=s
 var safe=64.0 if s.x/s.y>1.9 else 28.0
 strip.position=Vector2(safe-12,18);strip.size=Vector2(minf(690,s.x-2*safe-100),76)
 top.position=Vector2(safe+8,24);top.size=Vector2(strip.size.x-20,32);top.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
 objective.position=Vector2(safe+8,59)
 pause_button.position=Vector2(s.x-safe-76,20)
 action.position=Vector2(s.x-safe-240,s.y-105)
 bag.position=Vector2(safe+8,s.y-77);bag.size=Vector2(maxf(100,s.x-2*safe-275),62);bag.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 tip.position=Vector2(s.x*.5-240,107);tip.size=Vector2(480,30)
 if is_instance_valid(pause_panel):pause_panel.position=(s-pause_panel.size)*.5
 if is_instance_valid(result):result.position=(s-result.size)*.5
func refresh():
 if not is_instance_valid(top):return
 if get_viewport_rect().size!=last_size:layout()
 var done=0;var armed=0;var gathered=0
 for t in game.targets:
  if t.used:done+=1
  if t.armed:armed+=1
 for s in game.supplies:
  if s.taken:gathered+=1
 top.text="%02d/%02d   %s"%[game.index+1,game.CASES.size(),game.CASES[game.index].title]
 if game.escape_ready:objective.text="ЦЕЛЬ: ВЫЙТИ НЕЗАМЕЧЕННЫМ   /   ЖИЗНИ %d"%game.lives
 elif gathered<game.supplies.size():objective.text="ЦЕЛЬ: СОБРАТЬ ПРЕДМЕТЫ %d/%d   /   ЖИЗНИ %d"%[gathered,game.supplies.size(),game.lives]
 elif armed+done<game.targets.size():objective.text="ЦЕЛЬ: УСТАНОВИТЬ ЛОВУШКИ %d/%d   /   ЖИЗНИ %d"%[armed+done,game.targets.size(),game.lives]
 else:objective.text="ЦЕЛЬ: ДОЖДАТЬСЯ РЕАКЦИЙ %d/%d   /   ЖИЗНИ %d"%[done,game.targets.size(),game.lives]
 var items=[]
 for i in range(game.NAMES.size()):
  if game.inventory[i]>0:items.append("%s×%d"%[game.NAMES[i],game.inventory[i]])
 bag.text="РЮКЗАК: "+(", ".join(items) if not items.is_empty() else "пусто")+"   •   ДЕТАЛИ %d/%d   •   РЕАКЦИИ %d/%d"%[game.interactables.found_details,game.interactables.caches.size(),done,game.targets.size()]
 action.visible=game.state=="playing"
 action.text=game.hint()
 action.disabled=game.climbing>0 or game.paused or game.capture_time>0
 if game.capture_time>0:tip.text=game.capture_voice_caption
 elif game.message_time>0:tip.text=game.message_text
 elif game.hidden:tip.text="ТЫ В УКРЫТИИ"
 elif game.alert>.45:tip.text="Сосед гонится за тобой!"
 elif game.combo>1:tip.text="СЕРИЯ ПАКОСТЕЙ ×%d!"%game.combo
 elif game.escape_ready:tip.text="Нажми «К ВЫХОДУ»"
 elif game.elapsed<12:tip.text="Нажми на дверь, лестницу, ящик или предмет"
 else:tip.text="ЗАДАНИЕ: "+String(game.CASES[game.index].goal)
 queue_redraw()
func _draw():
 if not is_instance_valid(game):return
 if game.alert>.05:draw_rect(Rect2(last_size.x*.5-85,94,170*game.alert,6),Color(1,.32,.2,.9))
 var pos=Vector2(last_size.x*.5-120,125)
 draw_rect(Rect2(pos,Vector2(240,9)),Color(.08,.09,.1,.75))
 draw_rect(Rect2(pos,Vector2(240*game.anger,9)),Color(1,.29,.13,.95))
 if game.capture_time>0:draw_rect(Rect2(Vector2.ZERO,last_size),Color(1,.12,.08,.10+.08*absf(sin(game.capture_time*16))))
func make_panel()->PanelContainer:
 var p=PanelContainer.new();p.size=Vector2(500,360);p.position=(get_viewport_rect().size-p.size)*.5
 var style=StyleBoxFlat.new();style.bg_color=Color("14292f");style.set_corner_radius_all(24);style.set_border_width_all(2);style.border_color=Color("caa56a");style.content_margin_left=28;style.content_margin_right=28;style.content_margin_top=22;style.content_margin_bottom=22;p.add_theme_stylebox_override("panel",style);add_child(p);return p
func panel_button(box:VBoxContainer,text:String,callback:Callable):
 var b=Button.new();b.text=text;b.custom_minimum_size.y=70;b.add_theme_font_size_override("font_size",23)
 b.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
 for mode in ["normal","hover","pressed","focus"]:
  var style=StyleBoxFlat.new();style.bg_color=Color("2b4144") if mode=="normal" else (Color("4f645c") if mode=="hover" else Color("625b45"))
  style.border_color=Color("c9a773");style.set_border_width_all(1);style.set_corner_radius_all(14)
  b.add_theme_stylebox_override(mode,style)
 b.pressed.connect(callback);box.add_child(b)
func show_pause():
 if is_instance_valid(pause_panel):return
 game.set_paused(true);pause_panel=make_panel();var box=VBoxContainer.new();box.add_theme_constant_override("separation",10);pause_panel.add_child(box)
 var title=Label.new();title.text="ПАУЗА";title.add_theme_font_size_override("font_size",28);box.add_child(title)
 panel_button(box,"ПРОДОЛЖИТЬ",func():pause_panel.queue_free();pause_panel=null;game.set_paused(false))
 panel_button(box,"ГРАФИКА: "+("ДЕТАЛЬНАЯ" if game.quality else "ПЛАВНАЯ"),func():game.set_quality(not game.quality);pause_panel.queue_free();pause_panel=null;show_pause())
 panel_button(box,"В МЕНЮ",func():game.menu_requested.emit())
func show_result(won:bool):
 if is_instance_valid(result):result.queue_free()
 result=make_panel();var box=VBoxContainer.new();box.add_theme_constant_override("separation",15);result.add_child(box)
 var title=Label.new();title.text="ПАКОСТЬ УДАЛАСЬ!" if won else "ПОПРОБУЙ ЕЩЁ РАЗ";title.add_theme_font_size_override("font_size",27);box.add_child(title)
 var details=Label.new();details.text="%d с   /   Попался: %d   /   Серия: %d"%[int(game.elapsed),game.caught,game.best_combo];details.add_theme_font_size_override("font_size",22);box.add_child(details)
 var bonus_label=Label.new();bonus_label.text="БОНУС: "+("ПОЛУЧЕН" if game.bonus_awarded else "не получен")+" — "+game.bonus_description();bonus_label.add_theme_font_size_override("font_size",17);box.add_child(bonus_label)
 panel_button(box,"ДАЛЬШЕ" if won and game.index<game.CASES.size()-1 else "ПОВТОРИТЬ",func():game.start_case(mini(game.index+1,game.CASES.size()-1) if won and game.index<game.CASES.size()-1 else game.index))
 panel_button(box,"В МЕНЮ",func():game.menu_requested.emit())
func _input(event):
 var ui=result if is_instance_valid(result) else (pause_panel if is_instance_valid(pause_panel) else self)
 if preload("res://scripts/touch_ui.gd").handle(ui,event):get_viewport().set_input_as_handled()
 elif is_instance_valid(pause_panel) and (event is InputEventScreenTouch or event is InputEventScreenDrag):get_viewport().set_input_as_handled()
