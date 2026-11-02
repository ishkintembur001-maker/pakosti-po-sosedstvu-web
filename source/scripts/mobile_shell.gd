extends CanvasLayer
# Persistent orientation gate. Gameplay keeps its landscape layout; portrait is a
# readable rotation screen, never a miniature 16:9 game with unreachable buttons.
var overlay:Control
var heading:Label
var body:Label
var was_portrait=false
var frozen={}
func _ready():
 layer=100
 overlay=Control.new();overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(overlay)
 var bg=ColorRect.new();bg.color=Color("101f25");bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);overlay.add_child(bg)
 heading=Label.new();heading.text="ПОВЕРНИ ТЕЛЕФОН";heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;heading.add_theme_font_size_override("font_size",52);heading.modulate=Color("f4d192");overlay.add_child(heading)
 body=Label.new();body.text="Играй двумя руками\nСтик слева, действие справа\n\nИграем в горизонтальном режиме";body.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;body.add_theme_font_size_override("font_size",34);overlay.add_child(body)
 _process(0)
func _process(_dt):
 var size=get_viewport().get_visible_rect().size
 var portrait=OS.has_feature("mobile") and size.y>size.x
 overlay.visible=portrait
 if portrait:
  heading.position=Vector2(32,size.y*.32);heading.size=Vector2(size.x-64,80)
  body.position=Vector2(32,size.y*.32+120);body.size=Vector2(size.x-64,230)
 for game in get_tree().get_nodes_in_group("mobile_games"):
  var id=game.get_instance_id()
  if portrait and not frozen.has(id):frozen[id]=game.process_mode;game.process_mode=Node.PROCESS_MODE_DISABLED
  elif not portrait and frozen.has(id):game.process_mode=frozen[id];frozen.erase(id)
 was_portrait=portrait
func _input(event):
 if overlay.visible:
  if preload("res://scripts/touch_ui.gd").handle(overlay,event):get_viewport().set_input_as_handled()
  elif event is InputEventScreenTouch or event is InputEventScreenDrag or event is InputEventMouseButton:get_viewport().set_input_as_handled()
