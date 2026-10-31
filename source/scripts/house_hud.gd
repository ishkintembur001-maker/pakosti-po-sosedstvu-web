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
 action=button("ДЕЙСТВИЕ",Vector2.ZERO,Vector2(220,94),func():game.act());action.add_theme_font_size_override("font_size",22)
 layout()
func label(font_size:int,tint:Color)->Label:
 var l=Label.new();l.add_theme_font_size_override("font_size",font_size);l.modulate=tint;l.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(l);return l
func button(text:String,pos:Vector2,dimensions:Vector2,callback:Callable)->Button:
 var b=Button.new();b.text=text;b.position=pos;b.size=dimensions;b.focus_mode=Control.FOCUS_NONE
 for state in ["normal","hover","pressed"]:
  var style=StyleBoxFlat.new();style.bg_color=Color("2b464b") if state!="pressed" else Color("5a6550");style.border_color=Color("d2ad69");style.set_border_width_all(2);style.set_corner_radius_all(22);b.add_theme_stylebox_override(state,style)
 b.add_theme_font_size_override("font_size",22);b.pressed.connect(callback);add_child(b);return b
func layout():
 var s=get_viewport_rect().size;last_size=s
 var safe=64.0 if s.x/s.y>1.9 else 28.0
 strip.position=Vector2(safe-12,18);strip.size=Vector2(minf(580,s.x-2*safe-100),76)
 top.position=Vector2(safe+8,24);top.size=Vector2(strip.size.x-20,32);top.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
 objective.position=Vector2(safe+8,59)
 pause_button.position=Vector2(s.x-safe-76,20)
 game.stick_center=Vector2(safe+80,s.y-114)
 action.position=Vector2(s.x-safe-220,s.y-132)
 bag.position=Vector2(safe+195,s.y-73);bag.size=Vector2(maxf(80,s.x-2*safe-450),55);bag.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 tip.position=Vector2(s.x*.5-240,107);tip.size=Vector2(480,30)
 if is_instance_valid(pause_panel):pause_panel.position=(s-pause_panel.size)*.5
 if is_instance_valid(result):result.position=(s-result.size)*.5
func refresh():
 if not is_instance_valid(top):return
 if get_viewport_rect().size!=last_size:layout()
 var done=0
 for t in game.targets:
  if t.used:done+=1
 top.text=game.CASES[game.index].title
 objective.text="ЭТАЖ %d   /   ПАКОСТИ %d/%d   /   ЖИЗНИ %d"%[game.floor_id+1,done,game.targets.size(),game.lives]
 var items=[]
 for i in range(4):
  if game.inventory[i]:items.append(game.NAMES[i])
 bag.text="РЮКЗАК\n"+(", ".join(items) if not items.is_empty() else "пусто")
 var hint=game.hint();action.text=hint.replace(": ","\n")
 tip.text="ТЫ В УКРЫТИИ" if game.hidden else ("Сосед заметил тебя!" if game.alert>.45 else ("Нажми на предмет — герой подойдёт" if game.elapsed<8 else ""))
 action.disabled=game.state!="playing" or game.climbing>0 or game.paused
 queue_redraw()
func _draw():
 if not is_instance_valid(game):return
 var c=game.stick_center
 draw_circle(c,76,Color(.035,.065,.075,.65));draw_arc(c,76,0,TAU,64,Color(.9,.76,.48,.8),3,true)
 draw_circle(c+game.stick*48,32,Color(.86,.78,.59,.96))
 if game.alert>.05:draw_rect(Rect2(last_size.x*.5-85,94,170*game.alert,6),Color(1,.32,.2,.9))
func make_panel()->PanelContainer:
 var p=PanelContainer.new();p.size=Vector2(500,360);p.position=(get_viewport_rect().size-p.size)*.5
 var style=StyleBoxFlat.new();style.bg_color=Color("14292f");style.set_corner_radius_all(24);style.set_border_width_all(2);style.border_color=Color("caa56a");style.content_margin_left=28;style.content_margin_right=28;style.content_margin_top=22;style.content_margin_bottom=22;p.add_theme_stylebox_override("panel",style);add_child(p);return p
func panel_button(box:VBoxContainer,text:String,callback:Callable):
 var b=Button.new();b.text=text;b.custom_minimum_size.y=70;b.add_theme_font_size_override("font_size",23);b.pressed.connect(callback);box.add_child(b)
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
 var details=Label.new();details.text="%d с   /   Попался: %d"%[int(game.elapsed),game.caught];details.add_theme_font_size_override("font_size",22);box.add_child(details)
 panel_button(box,"ДАЛЬШЕ" if won and game.index<7 else "ПОВТОРИТЬ",func():game.start_case(mini(game.index+1,7) if won and game.index<7 else game.index))
 panel_button(box,"В МЕНЮ",func():game.menu_requested.emit())
func _input(event):
 var ui=result if is_instance_valid(result) else (pause_panel if is_instance_valid(pause_panel) else self)
 if preload("res://scripts/touch_ui.gd").handle(ui,event):get_viewport().set_input_as_handled()
 elif is_instance_valid(pause_panel) and (event is InputEventScreenTouch or event is InputEventScreenDrag):get_viewport().set_input_as_handled()
