extends Control
var game
var top:Label
var objective:Label
var action:Button
var result:PanelContainer
func _ready():
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_IGNORE
 var strip=ColorRect.new();strip.color=Color(.025,.045,.055,.9);strip.size=Vector2(960,80);strip.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(strip)
 top=Label.new();top.position=Vector2(20,10);top.add_theme_font_size_override("font_size",20);top.modulate=Color("efd7a2");add_child(top)
 objective=Label.new();objective.position=Vector2(20,43);objective.add_theme_font_size_override("font_size",15);add_child(objective)
 button("МЕНЮ",Vector2(850,15),Vector2(90,38),func():game.menu_requested.emit())
 action=button("ДЕЙСТВИЕ",Vector2(704,452),Vector2(235,60),func():game.act())
 var quality=button("ГРАФИКА",Vector2(737,14),Vector2(105,38),func():game.set_quality(not game.quality))
 quality.tooltip_text="Тени и разрешение 3D; клавиша Q"
 var help=Label.new();help.text="WASD / стрелки • E — действие\nНажми на пол для перемещения • Esc — меню";help.position=Vector2(211,473);help.add_theme_font_size_override("font_size",13);help.modulate=Color("d1d7d2");add_child(help)
func button(text:String,pos:Vector2,dimensions:Vector2,callback:Callable)->Button:
 var b=Button.new();b.text=text;b.position=pos;b.size=dimensions
 var style=StyleBoxFlat.new();style.bg_color=Color("25383c");style.border_color=Color("b29056");style.set_border_width_all(1);style.set_corner_radius_all(8);b.add_theme_stylebox_override("normal",style)
 b.add_theme_font_size_override("font_size",14);b.pressed.connect(callback);add_child(b);return b
func refresh():
 if not is_instance_valid(top):return
 var done=0
 for t in game.targets:
  if t.used:done+=1
 top.text="%02d  %s   |   ЭТАЖ %d   |   ЖИЗНИ %d"%[game.index+1,game.CASES[game.index].title,game.floor_id+1,game.lives]
 var bag=[]
 for i in range(4):
  if game.inventory[i]:bag.append(game.NAMES[i])
 objective.text="Пакости: %d / %d  •  Рюкзак: %s  •  %s"%[done,game.targets.size(),", ".join(bag) if not bag.is_empty() else "пуст", "ТИХО В УКРЫТИИ" if game.hidden else "Подбери предметы, подготовь ловушки и спрячься"]
 action.text=game.hint();queue_redraw()
func _draw():
 if not is_instance_valid(game):return
 var c=Vector2(100,451)
 draw_circle(c,63,Color(.04,.07,.08,.7));draw_arc(c,63,0,TAU,64,Color(.7,.62,.42,.8),2,true)
 draw_circle(c+game.stick*42,24,Color(.83,.77,.61,.9))
 if game.alert>.05:draw_rect(Rect2(400,84,160*game.alert,5),Color(1,.32,.2,.9))
func show_result(won:bool):
 if is_instance_valid(result):result.queue_free()
 result=PanelContainer.new();result.position=Vector2(255,155);result.size=Vector2(450,215);add_child(result)
 var style=StyleBoxFlat.new();style.bg_color=Color("172b30");style.content_margin_left=24;style.content_margin_right=24;style.content_margin_top=22;style.content_margin_bottom=22;style.set_corner_radius_all(14);style.border_color=Color("c5a46b");style.set_border_width_all(2);result.add_theme_stylebox_override("panel",style)
 var box=VBoxContainer.new();box.add_theme_constant_override("separation",14);result.add_child(box)
 var title=Label.new();title.text="ПАКОСТЬ УДАЛАСЬ!" if won else "СОСЕД ОКАЗАЛСЯ ХИТРЕЕ";title.add_theme_font_size_override("font_size",24);box.add_child(title)
 var details=Label.new();details.text="Время: %d с  •  Попался: %d"%[int(game.elapsed),game.caught];box.add_child(details)
 var next=Button.new();next.text="СЛЕДУЮЩЕЕ ЗАДАНИЕ" if won and game.index<7 else "ПОВТОРИТЬ";next.custom_minimum_size.y=42
 next.pressed.connect(func():result.queue_free();game.start_case(mini(game.index+1,7) if won and game.index<7 else game.index));box.add_child(next)
 var menu=Button.new();menu.text="В МЕНЮ";menu.custom_minimum_size.y=38;menu.pressed.connect(func():game.menu_requested.emit());box.add_child(menu)

func _input(event):
 var ui=result if is_instance_valid(result) else self
 if preload("res://scripts/touch_ui.gd").handle(ui,event):get_viewport().set_input_as_handled()
