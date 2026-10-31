extends Node3D

const HUD_SCRIPT = preload("res://scripts/hud_3d.gd")
const CUSTOM_WORLD_PATH = "res://assets/models/apartment_cast.glb"
const CUSTOM_CAST_PATH = "res://assets/models/cartoon_cast.glb"

var imported_world: Node3D

func imported_actor(enemy: bool) -> Dictionary:
	var avatar: Node3D
	if is_instance_valid(imported_world):
		var selected_name = "*NeighborCharacter*" if enemy else "*TricksterCharacter*"
		var template = imported_world.find_child(selected_name, true, false)
		if template is Node3D:
			avatar = template.duplicate()
	elif ResourceLoader.exists(CUSTOM_CAST_PATH):
		var resource = load(CUSTOM_CAST_PATH)
		if resource is PackedScene:
			var instance = resource.instantiate()
			var chosen_name = "*NeighborCharacter*" if enemy else "*TricksterCharacter*"
			var selected = instance.find_child(chosen_name, true, false)
			if selected is Node3D:
				avatar = selected.duplicate()
			instance.free()
	if not is_instance_valid(avatar):
		return {}
	var root = Node3D.new()
	root.name = "Neighbor" if enemy else "Player"
	world.add_child(root)
	root.add_child(avatar)
	avatar.position = Vector3.ZERO
	avatar.visible = true
	root.set_meta("high_detail", true)
	for part_name in ["Legs_L", "Legs_R", "Arm_L", "Arm_R"]:
		var limb = avatar.find_child(part_name + "*", true, false)
		if limb is Node3D:
			root.set_meta(part_name, limb)
	return {"node": root, "high_detail": true}

func apply_custom_apartment():
	imported_world = null
	if not ResourceLoader.exists(CUSTOM_WORLD_PATH):
		return
	var resource = load(CUSTOM_WORLD_PATH)
	if not (resource is PackedScene):
		return
	var scene = resource.instantiate()
	if not (scene is Node3D):
		scene.free()
		return
	var hero = scene.find_child("*TricksterCharacter*", true, false)
	var neighbor = scene.find_child("*NeighborCharacter*", true, false)
	var environment = scene.find_child("*ApartmentEnvironment*", true, false)
	if not (hero is Node3D) or not (neighbor is Node3D) or not (environment is Node3D):
		scene.free()
		return


	for child in world.get_children():
		if child is MeshInstance3D or child is Light3D:
			child.queue_free()
	scene.name = "ApartmentVisuals"
	world.add_child(scene)
	imported_world = scene
	hero.visible = false
	for episode in [1, 2, 3]:
		var detail = scene.find_child("EpisodeDetail%d" % episode, true, false)
		if detail is Node3D: detail.visible = level >= episode
	neighbor.visible = false
	var props = scene.find_child("PrankProps", true, false)
	if props is Node3D: props.visible = false
	for camera in scene.find_children("*", "Camera3D", true, false):
		camera.current = false
	for light in scene.find_children("*", "Light3D", true, false):
		light.visible = false

const PLAYER_SPEED = 3.55
const STICK_CENTER = Vector2(118, 477)
const STICK_RADIUS = 58.0
const NAV_CELL = 0.32
const NAV_OFFSET = Vector2(-7.52, -4.16)
const ACTION_ZONE = Rect2(760, 460, 177, 66)
const MENU_PLAY = Rect2(355, 329, 250, 68)
const ROUTE = [Vector2(4.3, -1.3), Vector2(1.2, -1.3), Vector2(0.0, -0.35), Vector2(0.0, 0.4), Vector2(1.2, 1.45), Vector2(4.3, 1.85), Vector2(1.2, 1.45), Vector2(0.0, 0.4), Vector2(0.0, -0.35), Vector2(1.2, -1.3)]
const TITLE = ["СУББОТНИЙ ПЕРЕПОЛОХ", "НОЧНАЯ СМЕНА", "ОПАСНЫЙ ЭТАЖ", "ФИНАЛ: ДВА СОСЕДА"]
const EPISODES = ["Первое дело: три ловушки и один сердитый сосед", "Тихий вечер: не выдавай себя", "Опасный этаж: внимательный сосед", "Большая пакость: два соседа"]
const SUPPLY_POINTS = [Vector2(-5.35, 1.15), Vector2(-1.9, 3.3), Vector2(-2.25, -1.2), Vector2(-3.1, 3.4)]
const PRANK_LINES = ["БАНАН! Вот это скольжение!", "КРАСКА! Новый стиль соседа!", "МЫЛО! Идеально чистый пол!", "КОНФЕТТИ! Сюрприз удался!"]

const TRAP_KINDS = ["БАНАН", "КРАСКА", "МЫЛО", "КОНФЕТТИ"]
const TRAP_COLORS = ["#f9d35a", "#e56f83", "#a1b7ee", "#74d7d0"]
const NEIGHBOR_SPEEDS = [1.3, 1.56, 1.8, 1.84]
const VISION = [2.8, 3.0, 3.25, 3.45]
const CLOSSETS = [Vector2(-6.5, -1.25), Vector2(1.5, 3.35)]
const BG = ["#f6e6c5", "#d2deed", "#cfe0d4", "#dac7e5"]

var performance_mode = false
var performance_clock = 0.0
var performance_frames = 0
var quality_selected = false
var state = 0
var level = 0
var unlocked = 0
var lives = 3
var score = 0
var player_pos = Vector2(-5.6, 2.2)
var player_hidden = false
var faces = Vector2(0.4, 1.0)
var walk_amount = 0.0
var game_time = 0.0
var safe_time = 0.0
var message = ""
var message_timer = 0.0
var stick_finger = -100
var stick_motion = Vector2.ZERO
var walk_path = PackedVector2Array()
var walk_goal = Vector2.ZERO
var active_auto_target = -1
var active_auto_kind = -1
var auto_move = false
var navigation: AStarGrid2D
var tapping_indicator = Vector2.ZERO
var tapping_timer = 0.0
var tutorial_shown = false
var help_visible = false
var camera_focus = Vector3.ZERO
var camera_offset = Vector3(8.5, 10.8, 12.5)
var walls = []
var traps = []
var enemies = []
var materials = {}
var world: Node3D
var actor: Node3D
var input_layer: CanvasLayer
var hud
var effect_time = 0.0
var effect_pos = Vector2.ZERO
var effect_type = 0
var supply_items = []
var inventory = [false, false, false, false]
var caught_count = 0
var prank_points = 0
var combo = 0
var combo_timer = 0.0
var episode_time = 0.0
var episode_best = 0
var camera_3d: Camera3D
var sfx_pickup: AudioStreamPlayer
var sfx_arm: AudioStreamPlayer
var sfx_prank: AudioStreamPlayer
var sfx_caught: AudioStreamPlayer
var sfx_victory: AudioStreamPlayer
var prank_particles = []


func _ready():
	var save = ConfigFile.new()
	if save.load("user://pakosti_progress_3d.cfg") == OK:
		unlocked = clampi(int(save.get_value("progress", "unlocked", 0)), 0, 3)
	init_camera()
	init_sounds()
	input_layer = CanvasLayer.new()
	add_child(input_layer)
	hud = HUD_SCRIPT.new()
	hud.game = self
	input_layer.add_child(hud)
	prepare_level(0)
	state = 0

func init_camera():
	var camera = Camera3D.new()
	camera.name = "IsometricCamera"
	camera_3d = camera
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 8.8
	camera.position = camera_offset
	add_child(camera)
	camera.look_at(Vector3(0, 0.0, 0), Vector3.UP)
	camera.current = true
	var sun = DirectionalLight3D.new()
	sun.name = "SoftSun"
	sun.rotation_degrees = Vector3(-48, -28, 0)
	sun.light_color = Color("#fff0d9")
	sun.light_energy = 0.72
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 28.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.shadow_bias = 0.035
	sun.shadow_normal_bias = 0.65
	add_child(sun)
	var env = WorldEnvironment.new()
	var sky = Environment.new()
	sky.background_mode = Environment.BG_COLOR
	sky.background_color = Color("#242c32")
	sky.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	sky.ambient_light_color = Color("#dce7f6")
	sky.ambient_light_energy = 0.36
	sky.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = sky
	add_child(env)

func init_sounds():
	sfx_pickup = make_sfx("res://assets/sfx/pickup.wav", -11.0)
	sfx_arm = make_sfx("res://assets/sfx/arm.wav", -11.0)
	sfx_prank = make_sfx("res://assets/sfx/prank.wav", -8.0)
	sfx_caught = make_sfx("res://assets/sfx/caught.wav", -10.0)
	sfx_victory = make_sfx("res://assets/sfx/victory.wav", -9.0)

func make_sfx(path: String, volume: float) -> AudioStreamPlayer:
	var p = AudioStreamPlayer.new()
	p.stream = load(path)
	p.volume_db = volume
	add_child(p)
	return p

func sound(p: AudioStreamPlayer):
	if is_instance_valid(p) and p.stream != null:
		p.stop()
		p.play()

func material(hex: String, glow: bool = false) -> StandardMaterial3D:
	var id = hex + ("-light" if glow else "-normal")
	if materials.has(id):
		return materials[id]
	var m = StandardMaterial3D.new()
	m.albedo_color = Color(hex)
	m.roughness = 0.68
	m.metallic = 0.0
	m.metallic_specular = 0.25
	if glow:
		m.emission_enabled = true
		m.emission = Color(hex)
		m.emission_energy_multiplier = 0.55
	materials[id] = m
	return m

func part(parent: Node3D, name: String, mesh: Mesh, pos: Vector3, color: String) -> MeshInstance3D:
	var node = MeshInstance3D.new()
	node.name = name
	node.mesh = mesh
	node.position = pos
	node.material_override = material(color)
	parent.add_child(node)
	return node

func box(parent: Node3D, name: String, pos: Vector3, size: Vector3, col: String) -> MeshInstance3D:
	var shape = BoxMesh.new()
	shape.size = size
	return part(parent, name, shape, pos, col)

func ball(parent: Node3D, name: String, pos: Vector3, radius: float, col: String) -> MeshInstance3D:
	var shape = SphereMesh.new()
	shape.radius = radius
	shape.height = radius * 2.0
	shape.radial_segments = 12
	shape.rings = 6
	return part(parent, name, shape, pos, col)

func cylinder(parent: Node3D, name: String, pos: Vector3, radius: float, height: float, col: String) -> MeshInstance3D:
	var shape = CylinderMesh.new()
	shape.top_radius = radius
	shape.bottom_radius = radius
	shape.height = height
	shape.radial_segments = 12
	return part(parent, name, shape, pos, col)

func flat(parent: Node3D, name: String, x: float, z: float, w: float, d: float, col: String, y: float = 0.01):
	box(parent, name, Vector3(x, y, z), Vector3(w, 0.04, d), col)

func obstacle(x: float, z: float, w: float, d: float):
	walls.append(Rect2(x - w * 0.5, z - d * 0.5, w, d))

func furniture(name: String, x: float, z: float, w: float, d: float, height: float, col: String, solid: bool = true):
	box(world, name, Vector3(x, height * 0.5, z), Vector3(w, height, d), col)
	if solid:
		obstacle(x, z, w, d)

func line_wall(x: float, z: float, w: float, d: float, h: float = 0.8):
	furniture("Wall", x, z, w, d, h, "#dfd3c6", true)
	box(world, "WoodenWallCap", Vector3(x, h + 0.055, z), Vector3(w + 0.06, 0.11, d + 0.06), "#8f6e61")

func make_apartment():
	walls.clear()
	var pallet = ["#eadac8", "#b9b9ca", "#c4c9bd", "#c4b5d3"][level]
	furniture("Floor", 0.0, 0.0, 15.9, 9.25, 0.22, "#62504a", false)
	flat(world, "Lounge", -3.9, -2.27, 7.35, 4.3, ["#f2dcc1", "#b2b5ce", "#c0d4cb", "#bcb4ce"][level])
	flat(world, "Kitchen", -3.9, 2.28, 7.35, 4.25, "#c9c7b6")
	flat(world, "Bedroom", 3.9, -2.27, 7.35, 4.3, ["#e5bcaa", "#b2a8b5", "#e0c7c2", "#aa97bb"][level])
	flat(world, "Bathroom", 3.9, 2.28, 7.35, 4.25, ["#a2d7cf", "#92b4c8", "#a2becc", "#91bbc2"][level])

	for i in range(1, 10):
		box(world, "WoodInlay", Vector3(-3.9, 0.037, -4.35 + i * 0.45), Vector3(7.2, 0.012, 0.02), "#d5bc9c")
	for i in range(1, 10):
		box(world, "BathTile", Vector3(0.15 + i * 0.75, 0.045, 2.22), Vector3(0.024, 0.014, 4.02), "#80aba9")
	for i in range(1, 6):
		box(world, "TileLine", Vector3(3.88, 0.046, 0.28 + i * 0.7), Vector3(7.3, 0.014, 0.027), "#80aba9")

	flat(world, "GreenHallRunner", 0.0, 0.0, 1.45, 1.63, "#a86c59", 0.065)
	for j in range(4):
		var side = -1.0 if j % 2 == 0 else 1.0
		var z = -1.0 if j < 2 else 1.0
		cylinder(world, "DoorThreshold", Vector3(side * 0.6, 0.065, z * 0.53), 0.14, 0.06, "#ddc69b")
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			box(world, "CornerDetail", Vector3(sx * 7.65, 0.19, sz * 4.4), Vector3(0.3, 0.36, 0.3), "#a67762")

	line_wall(-4.15, 0.0, 6.6, 0.16, 0.62)
	line_wall(4.15, 0.0, 6.6, 0.16, 0.62)
	line_wall(0.0, -2.7, 0.16, 3.5, 0.7)
	line_wall(0.0, 2.7, 0.16, 3.5, 0.7)

	line_wall(0, -4.61, 15.8, 0.14, 1.55)
	line_wall(-7.89, 0, 0.17, 9.3, 1.25)
	line_wall(7.89, 0, 0.17, 9.3, 0.55)
	line_wall(0, 4.61, 15.8, 0.14, 0.32)

	flat(world, "WovenCarpet", -4.5, -2.2, 4.1, 2.7, ["#b36457", "#7d627c", "#b88171", "#8775a4"][level], 0.052)
	furniture("CouchSeat", -5.4, -3.2, 2.65, 0.9, 0.5, "#4b8e91")
	furniture("CouchBack", -5.4, -3.66, 2.65, 0.3, 0.92, "#2e6674")
	box(world, "Cushion", Vector3(-5.7, 0.54, -3.12), Vector3(0.58, 0.18, 0.56), "#eac19d")
	box(world, "Cushion", Vector3(-4.7, 0.54, -3.12), Vector3(0.58, 0.18, 0.56), "#cf8d76")
	furniture("CoffeeTable", -4.4, -1.85, 1.5, 0.78, 0.42, "#805c42")
	box(world, "Cup", Vector3(-4.22, 0.48, -1.7), Vector3(0.18, 0.1, 0.18), "#fff7e8")
	furniture("TVStand", -1.6, -3.45, 0.4, 1.35, 0.65, "#694f45")
	box(world, "TV", Vector3(-1.6, 1.1, -3.45), Vector3(0.12, 0.85, 1.16), "#253444")
	box(world, "TVScreen", Vector3(-1.53, 1.13, -3.45), Vector3(0.02, 0.66, 0.94), "#59a9b9")

	furniture("KitchenCounter", -6.35, 2.85, 0.83, 2.4, 0.76, "#a47d63")
	box(world, "CounterTop", Vector3(-6.35, 0.84, 2.85), Vector3(0.92, 0.12, 2.5), "#f1e1c4")
	cylinder(world, "Sink", Vector3(-6.35, 0.92, 2.28), 0.28, 0.04, "#667b88")
	furniture("Oven", -4.6, 4.08, 1.15, 0.65, 0.74, "#687985")
	for ox in [-0.25, 0.25]:
		cylinder(world, "Hob", Vector3(-4.6 + ox, 0.78, 4.08), 0.18, 0.025, "#273343")
	furniture("DiningTable", -3.15, 2.1, 1.45, 1.05, 0.6, "#c5986e")
	box(world, "TableTop", Vector3(-3.15, 0.66, 2.1), Vector3(1.55, 0.13, 1.12), "#eacba6")
	for cx in [-2.05, -4.25]:
		furniture("DiningChair", cx, 2.1, 0.49, 0.51, 0.43, "#7a9a98")

	flat(world, "BedroomRug", 4.0, -1.95, 4.3, 3.2, "#c8949e", 0.052)
	furniture("BedFrame", 4.8, -3.0, 2.65, 2.07, 0.43, "#785c69")
	box(world, "Mattress", Vector3(4.8, 0.53, -3), Vector3(2.42, 0.24, 1.87), "#fff5e8")
	for bx in [4.05, 5.55]:
		box(world, "Pillow", Vector3(bx, 0.72, -3.5), Vector3(0.6, 0.15, 0.43), "#b9d4d8")
	furniture("Nightstand", 6.72, -3.4, 0.55, 0.61, 0.62, "#926f55")
	cylinder(world, "LampBase", Vector3(6.72, 0.76, -3.4), 0.17, 0.15, "#f0ca7b")
	ball(world, "LampGlow", Vector3(6.72, 0.99, -3.4), 0.18, "#ffda8c")

	furniture("TubFrame", 5.1, 3.45, 2.5, 1.35, 0.46, "#e6f8ee")
	box(world, "BathWater", Vector3(5.1, 0.48, 3.45), Vector3(2.12, 0.025, 1.03), "#73bed2")
	furniture("WashBasin", 6.85, 1.28, 0.58, 0.95, 0.64, "#e6e9df")
	cylinder(world, "Basin", Vector3(6.85, 0.76, 1.28), 0.3, 0.04, "#a2cad3")

	for j in range(3):
		var px = -6.0 + float(j) * 1.42
		box(world, "LoungePosterFrame", Vector3(px, 1.1, -4.46), Vector3(1.0, 0.76, 0.11), "#62463f")
		box(world, "PosterArt", Vector3(px, 1.1, -4.392), Vector3(0.83, 0.58, 0.025), ["#82b6b0", "#e9b277", "#c1808b"][j])
		ball(world, "PosterSun", Vector3(px + 0.23, 1.24, -4.368), 0.12, "#fff0bc")
	for j in range(4):
		var sx = -2.3 + float(j) * 0.31
		box(world, "KitchenSpice", Vector3(sx, 0.3, 4.15), Vector3(0.2, 0.45, 0.15), ["#bf795e", "#dec197", "#739f86", "#a47b9e"][j])
		box(world, "SpiceCap", Vector3(sx, 0.56, 4.15), Vector3(0.23, 0.07, 0.18), "#ede2cb")
	box(world, "KitchenFridge", Vector3(-7.0, 0.83, 1.0), Vector3(0.72, 1.65, 0.78), "#cfddd9")
	box(world, "FridgeHandle", Vector3(-6.54, 1.0, 1.0), Vector3(0.04, 0.52, 0.1), "#7d9693")
	obstacle(-7.0, 1.0, 0.72, 0.78)
	for j in range(3):
		box(world, "WallBacksplash", Vector3(-6.81, 0.27 + float(j) * 0.16, 3.1), Vector3(0.03, 0.07, 1.7), "#c9b48e")

	for spot in [Vector2(4.3, -1.3), Vector2(4.3, 1.85), Vector2(0, 0.38)]:
		cylinder(world, "PrankMark", Vector3(spot.x, 0.1, spot.y), 0.49, 0.03, "#dfbc80")

	box(world, "BedBlanket", Vector3(4.8, 0.69, -2.52), Vector3(2.3, 0.12, 0.77), "#96b0c8")
	for j in range(4):
		box(world, "BlanketStripe", Vector3(3.95 + float(j) * 0.55, 0.76, -2.52), Vector3(0.1, 0.015, 0.7), "#e4d0b5")

	for j in range(4):
		var px = 4.1 + float(j) * 0.5
		cylinder(world, "BathBubble", Vector3(px, 0.65, 3.45), 0.06 + float(j) * 0.01, 0.025, "#d8f6f2")


	for cp in CLOSSETS:
		furniture("Closet", cp.x, cp.y, 0.9, 0.8, 1.62, "#9a7355")
		box(world, "ClosetDoor", Vector3(cp.x, 0.86, cp.y + 0.43), Vector3(0.8, 1.45, 0.055), "#b38d63")
		for delta in [-0.15, 0.15]:
			ball(world, "DoorKnob", Vector3(cp.x + delta, 0.9, cp.y + 0.48), 0.042, "#f3d28b")
		cylinder(world, "SafeRing", Vector3(cp.x, 0.08, cp.y), 0.59, 0.07, "#71b0a0")

	for spot in [Vector2(-5.15, -1.0), Vector2(6.8, -1.3), Vector2(-6.8, 3.9), Vector2(0.65, -3.55)]:
		var px: float = spot.x
		var pz: float = spot.y
		cylinder(world, "PlantPot", Vector3(px, 0.24, pz), 0.23, 0.45, "#9f6d52")
		cylinder(world, "PlantStem", Vector3(px, 0.7, pz), 0.06, 0.6, "#466b50")
		for j in range(5):
			var ang: float = j * TAU / 5.0
			ball(world, "Leaf", Vector3(px + cos(ang) * 0.25, 0.91, pz + sin(ang) * 0.25), 0.24, "#4c9c69")
	for light_spot in [Vector2(-3.2, -2.2), Vector2(4.4, -2.0), Vector2(-3.2, 2.0), Vector2(4.5, 2.0)]:
		var lx: float = light_spot.x
		var lz: float = light_spot.y
		var light = OmniLight3D.new()
		light.position = Vector3(lx, 2.3, lz)
		light.light_color = Color("#ffe0b5") if level < 2 else Color("#c6dbff")
		light.light_energy = 0.28
		light.omni_range = 5.2
		light.shadow_enabled = false
		world.add_child(light)

	if level >= 1:
		furniture("ExtraBookshelf", -1.15, 2.95, 0.4, 1.28, 1.3, "#906b65")
		for j in range(4):
			box(world, "Books", Vector3(-1.15, 0.37 + j * 0.24, 2.95), Vector3(0.45, 0.1, 0.88), ["#dfbb87", "#7299b0", "#b97e78", "#d9cc98"][j])
	if level >= 2:
		furniture("ExtraPartition", 5.85, -1.05, 0.6, 0.44, 0.8, "#916c68")
	if level == 3:
		furniture("BoxStack", -2.0, -2.82, 0.8, 0.78, 0.82, "#b38963")
	obstacle(-2.6, -4.12, 1.47, 0.55)
	obstacle(-3.77, -3.6, 0.58, 0.61)
	apply_custom_apartment()

func make_person(col: String, enemy: bool) -> Dictionary:
	var imported = imported_actor(enemy)
	if imported.has("node"):
		return imported
	var root = Node3D.new()
	root.name = "Neighbor" if enemy else "Player"
	world.add_child(root)
	cylinder(root, "FeetShadow", Vector3(0, 0.025, 0), 0.45, 0.028, "#353c42")

	var torso = CapsuleMesh.new()
	torso.radius = 0.33 if enemy else 0.275
	torso.height = 1.08 if enemy else 0.93
	torso.radial_segments = 16
	torso.rings = 6
	part(root, "Torso", torso, Vector3(0, 0.84, 0), col)
	ball(root, "Scarf", Vector3(0, 1.19, 0), 0.29 if enemy else 0.22, "#f4deb5" if enemy else "#e7be65")
	ball(root, "Head", Vector3(0, 1.48, 0), 0.3 if enemy else 0.28, "#efb18a" if enemy else "#f5bb93")
	ball(root, "Hair", Vector3(0, 1.69, -0.03), 0.255, "#40333b" if enemy else "#292b36")
	for x in [-0.1, 0.1]:
		ball(root, "Ear", Vector3(x * 3.1, 1.47, 0), 0.065, "#eeb18f")
		ball(root, "EyeWhite", Vector3(x, 1.52, 0.264), 0.07, "#fafaf2")
		ball(root, "Pupil", Vector3(x, 1.52, 0.327), 0.032, "#273342")
		box(root, "Eyebrow", Vector3(x, 1.635, 0.248), Vector3(0.11, 0.035, 0.06), "#473844")
	ball(root, "Nose", Vector3(0, 1.43, 0.3), 0.075, "#d99171")
	box(root, "Smile", Vector3(0, 1.32, 0.28), Vector3(0.17, 0.035, 0.06), "#8b5551")
	ball(root, "LeftCheek", Vector3(-0.18, 1.39, 0.2), 0.06, "#d8897d")
	ball(root, "RightCheek", Vector3(0.18, 1.39, 0.2), 0.06, "#d8897d")
	box(root, "Belt", Vector3(0, 0.49, 0), Vector3(0.46, 0.1, 0.44), "#3a3943")
	var left_leg = box(root, "LeftLeg", Vector3(-0.14, 0.22, 0), Vector3(0.19, 0.47, 0.23), "#293647")
	var right_leg = box(root, "RightLeg", Vector3(0.14, 0.22, 0), Vector3(0.19, 0.47, 0.23), "#293647")
	var left_arm = box(root, "LeftArm", Vector3(-0.4, 0.83, 0), Vector3(0.19, 0.54, 0.22), col)
	var right_arm = box(root, "RightArm", Vector3(0.4, 0.83, 0), Vector3(0.19, 0.54, 0.22), col)
	for x in [-0.14, 0.14]:
		box(root, "Shoe", Vector3(x, 0.07, 0.12), Vector3(0.25, 0.15, 0.42), "#31343e")
	if enemy:
		ball(root, "BigBelly", Vector3(0, 0.83, 0.22), 0.3, col)
		box(root, "Mustache", Vector3(0, 1.35, 0.32), Vector3(0.27, 0.07, 0.1), "#54352e")
		cylinder(root, "Hat", Vector3(0, 1.79, 0), 0.32, 0.17, "#473d41")
		box(root, "HatBand", Vector3(0, 1.77, 0), Vector3(0.61, 0.055, 0.4), "#e0ad70")
		box(root, "Tie", Vector3(0, 0.94, 0.34), Vector3(0.13, 0.32, 0.085), "#f4d29b")
	else:
		box(root, "Backpack", Vector3(0, 0.86, -0.35), Vector3(0.44, 0.65, 0.18), "#d5a34e")
		box(root, "BackpackPocket", Vector3(0, 0.69, -0.465), Vector3(0.32, 0.22, 0.04), "#b68541")
		cylinder(root, "Cap", Vector3(0, 1.77, 0), 0.28, 0.14, "#244869")
		box(root, "CapVisor", Vector3(0, 1.75, 0.22), Vector3(0.52, 0.06, 0.35), "#214463")
		box(root, "HoodieZip", Vector3(0, 0.99, 0.282), Vector3(0.045, 0.35, 0.05), "#e9e6e1")
	return {"node": root, "lleg": left_leg, "rleg": right_leg, "larm": left_arm, "rarm": right_arm}

func make_trap(p: Vector2, kind: int) -> Dictionary:
	var n = Node3D.new()
	n.position = Vector3(p.x, 0.07, p.y)
	world.add_child(n)
	cylinder(n, "Plate", Vector3.ZERO, 0.39, 0.12, "#3a4750")
	var colors = ["#f9d35a", "#e56f83", "#a1b7ee", "#74d7d0"]
	if kind == 0:
		var peel = cylinder(n, "BananaPeel", Vector3(0, 0.26, 0), 0.13, 0.32, "#ffe260")
		peel.rotation.x = 0.32
		for wing in [-1.0, 1.0]:
			var banana_tip = box(n, "BananaTip", Vector3(wing * 0.18, 0.2, 0), Vector3(0.27, 0.065, 0.11), "#eec44c")
			banana_tip.rotation.z = wing * 0.45
	elif kind == 1:
		cylinder(n, "PaintTin", Vector3(0, 0.25, 0), 0.21, 0.35, "#cf627a")
		cylinder(n, "PaintRim", Vector3(0, 0.43, 0), 0.24, 0.055, "#f5c7d1")
		for drop in [-0.16, 0.16]:
			ball(n, "PaintDrop", Vector3(drop, 0.06, 0.22), 0.065, "#ec90a9")
	elif kind == 2:
		box(n, "Soap", Vector3(0, 0.22, 0), Vector3(0.38, 0.14, 0.25), "#b7dff7")
		for bubble in range(3):
			ball(n, "Bubble", Vector3(-0.15 + bubble * 0.15, 0.36 + bubble * 0.12, 0), 0.07, "#eafcfe")
	else:
		var confetti = cylinder(n, "PartyPopper", Vector3(0, 0.28, 0), 0.16, 0.42, "#70d6ba")
		confetti.rotation.z = -0.55
		ball(n, "PopperTip", Vector3(0.2, 0.52, 0), 0.11, "#fae89a")
	var ring = TorusMesh.new()
	ring.inner_radius = 0.44
	ring.outer_radius = 0.49
	ring.ring_segments = 24
	ring.rings = 4
	var orbit = part(n, "ArmedGlow", ring, Vector3(0, 0.11, 0), "#67ffd4")
	orbit.visible = false
	attach_prop(n, kind, orbit)
	return {"pos": p, "kind": kind, "name": TRAP_KINDS[kind], "armed": false, "used": false, "node": n, "glow": orbit}

func make_supply(p: Vector2, kind: int) -> Dictionary:
	var root = Node3D.new()
	root.name = "Collectible_%d" % kind
	root.position = Vector3(p.x, 0.12, p.y)
	world.add_child(root)
	var tint = TRAP_COLORS[kind]
	var ring = TorusMesh.new()
	ring.inner_radius = 0.33
	ring.outer_radius = 0.39
	ring.ring_segments = 24
	ring.rings = 4
	var halo = part(root, "GoldenMarker", ring, Vector3(0, 0.075, 0), "#f4dc9e")
	cylinder(root, "Pedestal", Vector3(0, 0.12, 0), 0.25, 0.16, "#725d60")
	ball(root, "Collectible", Vector3(0, 0.43, 0), 0.24, tint)

	if kind == 0:
		var banana = cylinder(root, "Banana", Vector3(0, 0.5, 0), 0.11, 0.4, "#ffdc53")
		banana.rotation.z = 0.5
	elif kind == 1:
		box(root, "PaintTin", Vector3(0, 0.5, 0), Vector3(0.29, 0.29, 0.29), "#e56276")
		box(root, "PaintLid", Vector3(0, 0.67, 0), Vector3(0.35, 0.06, 0.35), "#f3c7bb")
	elif kind == 2:
		box(root, "SoapBar", Vector3(0, 0.51, 0), Vector3(0.37, 0.15, 0.24), "#b6d8ff")
		ball(root, "Bubble", Vector3(0.14, 0.72, 0), 0.11, "#ecffff")
	else:
		cylinder(root, "Popper", Vector3(0, 0.55, 0), 0.15, 0.37, "#6fd7c9")
		ball(root, "PaperStar", Vector3(0, 0.8, 0), 0.13, "#fff1ab")
	attach_prop(root, kind, halo)
	return {"kind": kind, "pos": p, "node": root, "taken": false, "halo": halo}

func action_hint() -> String:
	if state != 1: return ""
	if player_hidden: return "ВЫЙТИ ИЗ ШКАФА"
	for item in supply_items:
		if not item["taken"] and player_pos.distance_to(item["pos"]) < 1.15:
			return "ПОДОБРАТЬ: " + TRAP_KINDS[item["kind"]]
	for t in traps:
		if not t["armed"] and not t["used"] and player_pos.distance_to(t["pos"]) < 1.3:
			if inventory[t["kind"]]: return "УСТАНОВИТЬ: " + str(t["name"])
			return "НУЖЕН ПРЕДМЕТ: " + str(t["name"])
	for closet in CLOSSETS:
		if player_pos.distance_to(closet) < 1.35: return "СПРЯТАТЬСЯ В ШКАФ"
	return ""

func prepare_level(n: int):
	level = clampi(n, 0, 3)
	if is_instance_valid(world):
		world.free()
	world = Node3D.new()
	world.name = "Apartment3D"
	add_child(world)
	make_apartment()
	build_navigation()
	player_pos = Vector2(-5.6, 2.2)
	faces = Vector2(0.4, 1.0)
	lives = 4 if level == 3 else 3
	score = 0
	caught_count = 0
	prank_points = 0
	combo = 0
	combo_timer = 0.0
	episode_time = 0.0
	inventory = [false, false, false, false]
	safe_time = 3.0
	player_hidden = false
	stick_finger = -100
	stick_motion = Vector2.ZERO
	auto_move = false
	walk_path = PackedVector2Array()
	active_auto_target = -1
	active_auto_kind = -1
	tapping_timer = 0.0
	effect_time = 0
	actor = make_person("#367db5", false)["node"]
	set_actor_position(actor, player_pos)
	traps = []
	traps.append(make_trap(Vector2(4.3, -1.3), 0))
	traps.append(make_trap(Vector2(4.3, 1.85), 1))
	traps.append(make_trap(Vector2(0.0, 0.38), 2))
	if level == 3:
		traps.append(make_trap(Vector2(1.2, -1.3), 3))
	supply_items = []
	for t in traps:
		supply_items.append(make_supply(SUPPLY_POINTS[t["kind"]], t["kind"]))
	prank_particles.clear()
	enemies = []
	var first = make_person("#c45858", true)
	first["pos"] = ROUTE[0]
	first["node"].position = Vector3(ROUTE[0].x, 0, ROUTE[0].y)
	first["waypoint"] = 1
	first["stun"] = 1.5
	first["alert"] = 0.0
	first["mode"] = "patrol"
	first["search"] = 0.0
	first["face"] = Vector2.LEFT
	first["route"] = ROUTE
	first["path"] = PackedVector2Array()
	first["path_timer"] = 0.0
	enemies.append(first)
	if level == 3:
		var rival = make_person("#8056a4", true)
		rival["pos"] = ROUTE[5]
		rival["node"].position = Vector3(ROUTE[5].x, 0, ROUTE[5].y)
		rival["waypoint"] = 6
		rival["stun"] = 4.0
		rival["alert"] = 0.0
		rival["mode"] = "patrol"
		rival["search"] = 0.0
		rival["face"] = Vector2.LEFT
		rival["route"] = ROUTE
		rival["path"] = PackedVector2Array()
		rival["path_timer"] = 0.0
		enemies.append(rival)
	tell("НАЙДИ ПРЕДМЕТЫ И УСТРОЙ ТРИ ПАКОСТИ!")
	if is_instance_valid(camera_3d):
		camera_focus = Vector3(player_pos.x * 0.68, 0, player_pos.y * 0.68)
		camera_3d.position = camera_focus + camera_offset
		camera_3d.look_at(camera_focus, Vector3.UP)
	if is_instance_valid(hud): hud.queue_redraw()

func tell(s: String):
	message = s
	message_timer = 3.4

func start_level(n: int):
	prepare_level(n)
	state = 1

func on_action():
	if state != 1: return
	if player_hidden:
		player_hidden = false
		tell("ТЫ ВЫШЕЛ ИЗ УКРЫТИЯ")
		return
	for item in supply_items:
		if not item["taken"] and player_pos.distance_to(item["pos"]) < 1.08:
			item["taken"] = true
			item["node"].visible = false
			inventory[item["kind"]] = true
			sound(sfx_pickup)
			tell("В РЮКЗАКЕ: " + TRAP_KINDS[item["kind"]])
			return
	for t in traps:
		if not t["armed"] and not t["used"] and player_pos.distance_to(t["pos"]) < 1.08:
			if not inventory[t["kind"]]:
				tell("НАЙДИ СНАЧАЛА: " + str(t["name"]))
				return
			t["armed"] = true
			inventory[t["kind"]] = false
			t["glow"].visible = true
			sound(sfx_arm)
			tell("ГОТОВО! ТЕПЕРЬ ПРЯЧЬСЯ")
			return
	for closet in CLOSSETS:
		if player_pos.distance_to(closet) < 1.12:
			player_hidden = true
			sound(sfx_arm)
			tell("ТИШЕ! СОСЕД ТЕБЯ НЕ ВИДИТ")
			return
	tell("ИЩИ ПРЕДМЕТЫ И ЛОВУШКИ С ПОДСВЕТКОЙ")

func navigation_cell(world_pos: Vector2) -> Vector2i:
	var x = roundi((world_pos.x - NAV_OFFSET.x) / NAV_CELL)
	var y = roundi((world_pos.y - NAV_OFFSET.y) / NAV_CELL)
	return Vector2i(clampi(x, 0, 47), clampi(y, 0, 26))

func build_navigation():
	navigation = AStarGrid2D.new()
	navigation.region = Rect2i(0, 0, 48, 27)
	navigation.cell_size = Vector2(NAV_CELL, NAV_CELL)
	navigation.offset = NAV_OFFSET
	navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	navigation.update()
	for y in range(27):
		for x in range(48):
			var point = NAV_OFFSET + Vector2(x, y) * NAV_CELL
			if blocked(point):
				navigation.set_point_solid(Vector2i(x, y), true)

func nearest_walkable(pos: Vector2) -> Vector2i:
	var c = navigation_cell(pos)
	if not navigation.is_point_solid(c): return c
	var chosen = c
	var best = 9999.0
	for y in range(27):
		for x in range(48):
			var q = Vector2i(x, y)
			if not navigation.is_point_solid(q):
				var score = Vector2(x, y).distance_squared_to(Vector2(c))
				if score < best:
					chosen = q
					best = score
	return chosen

func walking_destination(pos: Vector2, kind: int) -> Vector2:
	if kind < 0: return pos
	var options = [pos + Vector2(0.78, 0), pos + Vector2(-0.78, 0), pos + Vector2(0, 0.78), pos + Vector2(0, -0.78)]
	var chosen = player_pos
	var best = 9999.0
	for c in options:
		if not blocked(c):
			var score = player_pos.distance_squared_to(c)
			if score < best:
				chosen = c
				best = score
	return chosen

func plan_walk(pos: Vector2, kind: int = -1, index: int = -1):
	if not is_instance_valid(navigation): return
	var dest = walking_destination(pos, kind)
	var start_cell = nearest_walkable(player_pos)
	var end_cell = nearest_walkable(dest)
	var points = navigation.get_point_path(start_cell, end_cell)
	if points.size() <= 1:
		auto_move = false
		return
	walk_path = points
	walk_goal = pos
	active_auto_kind = kind
	active_auto_target = index
	auto_move = true
	tapping_indicator = dest
	tapping_timer = 1.3
	tell("ИДУ К ЦЕЛИ — МОЖНО ВЗЯТЬ УПРАВЛЕНИЕ ДЖОЙСТИКОМ")

func touch_target(screen_pos: Vector2):
	if not is_instance_valid(camera_3d): return
	var origin = camera_3d.project_ray_origin(screen_pos)
	var ray = camera_3d.project_ray_normal(screen_pos)
	if absf(ray.y) < 0.0001: return
	var distance = - origin.y / ray.y
	if distance < 0.0: return
	var world_point = origin + ray * distance
	var goal = Vector2(clampf(world_point.x, -7.2, 7.2), clampf(world_point.z, -3.9, 3.9))
	var target_kind = -1
	var target_index = -1
	var target_dist = 1.1
	for i in range(supply_items.size()):
		var item = supply_items[i]
		if not item["taken"] and goal.distance_to(item["pos"]) < target_dist:
			target_kind = 0
			target_index = i
			target_dist = goal.distance_to(item["pos"])
			goal = item["pos"]
	for i in range(traps.size()):
		var trap = traps[i]
		if not trap["used"] and not trap["armed"] and goal.distance_to(trap["pos"]) < target_dist:
			target_kind = 1
			target_index = i
			target_dist = goal.distance_to(trap["pos"])
			goal = trap["pos"]
	for i in range(CLOSSETS.size()):
		if goal.distance_to(CLOSSETS[i]) < target_dist:
			target_kind = 2
			target_index = i
			target_dist = goal.distance_to(CLOSSETS[i])
			goal = CLOSSETS[i]
	plan_walk(goal, target_kind, target_index)

func joystick_vector() -> Vector2:
	return stick_motion.limit_length(1.0)

func touch_joystick(pos: Vector2):
	stick_motion = (pos - STICK_CENTER) / STICK_RADIUS
	if stick_motion.length() > 1.0: stick_motion = stick_motion.normalized()

func tap_action_ready() -> bool:
	if active_auto_kind == 0 and active_auto_target >= 0 and active_auto_target < supply_items.size():
		return player_pos.distance_to(supply_items[active_auto_target]["pos"]) < 1.05
	if active_auto_kind == 1 and active_auto_target >= 0 and active_auto_target < traps.size():
		return player_pos.distance_to(traps[active_auto_target]["pos"]) < 1.05
	if active_auto_kind == 2 and active_auto_target >= 0 and active_auto_target < CLOSSETS.size():
		return player_pos.distance_to(CLOSSETS[active_auto_target]) < 1.05
	return false

func menu_click(p: Vector2):
	if state == 0:
		for j in range(4):
			if Rect2(196 + j * 145, 239, 130, 63).has_point(p):
				if j <= unlocked: start_level(j)
				return
		if MENU_PLAY.has_point(p): start_level(unlocked)
	elif state == 1:
		if ACTION_ZONE.has_point(p): on_action()
	elif state == 2:
		if MENU_PLAY.has_point(p): start_level(mini(3, level + 1))
	elif state == 3:
		if MENU_PLAY.has_point(p): start_level(level)
	elif state == 4:
		if MENU_PLAY.has_point(p): state = 0

func _input(e):
	if state == 1 and ((e is InputEventScreenTouch and e.pressed) or (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT)):
		if Rect2(330, 12, 236, 43).has_point(e.position):
			set_performance_mode(not performance_mode)
			quality_selected = true
			return
	if e is InputEventScreenTouch:
		if e.pressed:
			if state == 1 and e.position.x < 257 and e.position.y > 409:
				stick_finger = e.index
				touch_joystick(e.position)
				auto_move = false
			elif state == 1 and ACTION_ZONE.has_point(e.position):
				auto_move = false
				on_action()
			elif state == 1 and e.position.y >= 72 and e.position.y < 422:
				touch_target(e.position)
			else:
				menu_click(e.position)
		else:
			if e.index == stick_finger:
				stick_finger = -100
				stick_motion = Vector2.ZERO
	elif e is InputEventScreenDrag:
		if e.index == stick_finger:
			touch_joystick(e.position)
	elif e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			if state == 1 and e.position.x < 257 and e.position.y > 409:
				stick_finger = -1
				touch_joystick(e.position)
				auto_move = false
			elif state == 1 and ACTION_ZONE.has_point(e.position):
				auto_move = false
				on_action()
			elif state == 1 and e.position.y >= 72 and e.position.y < 422:
				touch_target(e.position)
			else:
				menu_click(e.position)
		elif stick_finger == -1:
			stick_finger = -100
			stick_motion = Vector2.ZERO
	elif e is InputEventMouseMotion and stick_finger == -1:
		touch_joystick(e.position)
	elif e is InputEventKey and e.pressed and not e.echo:
		if e.keycode == KEY_E or e.keycode == KEY_SPACE:
			if state == 1: on_action()
			elif state == 0: start_level(unlocked)
			elif state == 2: start_level(mini(3, level + 1))
			elif state == 3: start_level(level)
			else: state = 0
		elif e.keycode == KEY_Q:
			set_performance_mode(not performance_mode)
			quality_selected = true
		elif e.keycode == KEY_R: start_level(level)
		elif e.keycode == KEY_ESCAPE: state = 0
		elif e.keycode == KEY_H and state == 1: help_visible = not help_visible
		elif state == 0 and e.keycode >= KEY_1 and e.keycode <= KEY_4:
			var select = e.keycode - KEY_1
			if select <= unlocked: start_level(select)

func blocked(p: Vector2) -> bool:
	if absf(p.x) > 7.4 or absf(p.y) > 4.05: return true
	var radius = 0.3
	for w in walls:
		if w.grow(radius).has_point(p): return true
	return false

func move_player(dt: float):
	var input = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if Input.is_key_pressed(KEY_A): input.x -= 1
	if Input.is_key_pressed(KEY_D): input.x += 1
	if Input.is_key_pressed(KEY_W): input.y -= 1
	if Input.is_key_pressed(KEY_S): input.y += 1
	input += joystick_vector()
	if input.length() > 1.0: input = input.normalized()
	if input.length() > 0.12 and auto_move:
		auto_move = false
		walk_path = PackedVector2Array()
	var motion = Vector2.ZERO
	if input.length() > 0.12:
		var forward = Vector2(camera_offset.x, camera_offset.z).normalized()
		motion = Vector2(input.x * forward.y + input.y * forward.x, -input.x * forward.x + input.y * forward.y)
	elif auto_move:
		while walk_path.size() > 0 and player_pos.distance_to(walk_path[0]) < 0.29:
			walk_path.remove_at(0)
		if tap_action_ready():
			auto_move = false
			walk_path = PackedVector2Array()
			on_action()
		elif walk_path.size() > 0:
			var to_point = walk_path[0] - player_pos
			if to_point.length_squared() > 0.02:
				motion = to_point.normalized() * minf(1.0, to_point.length() / maxf(1e-05, PLAYER_SPEED * dt))
		else:
			auto_move = false
	walk_amount = motion.length()
	if walk_amount > 0.08 and player_hidden: player_hidden = false
	if not player_hidden:
		var step = motion * PLAYER_SPEED * dt
		var new_point = player_pos + Vector2(step.x, 0)
		if not blocked(new_point): player_pos = new_point
		new_point = player_pos + Vector2(0, step.y)
		if not blocked(new_point): player_pos = new_point
	if motion.length() > 0.08:
		faces = motion.normalized()
	actor.visible = not player_hidden
	set_actor_position(actor, player_pos)
	actor.rotation.y = atan2(faces.x, faces.y)
	animate_avatar(actor, walk_amount, game_time)

func set_actor_position(node: Node3D, p: Vector2):
	node.position = Vector3(p.x, 0, p.y)

func animate_avatar(node: Node3D, speed: float, clock: float):
	if not is_instance_valid(node): return
	var swing = sin(clock * 10.2) * 0.35 * speed
	if node.has_meta("high_detail"):
		for label in ["Legs_L", "Legs_R", "Arm_L", "Arm_R"]:
			if node.has_meta(label):
				var limb = node.get_meta(label)
				if is_instance_valid(limb) and limb is Node3D:
					var direction = 1.0 if label == "Legs_L" or label == "Arm_R" else -1.0
					limb.rotation.x = direction * swing
	else:
		var left_leg = node.get_node("LeftLeg")
		var right_leg = node.get_node("RightLeg")
		var left_arm = node.get_node("LeftArm")
		var right_arm = node.get_node("RightArm")
		left_leg.rotation.x = swing
		right_leg.rotation.x = - swing
		left_arm.rotation.x = - swing
		right_arm.rotation.x = swing
	node.position.y = (absf(sin(clock * 10.2)) * 0.035 * speed)

func spawn_comic_burst(where: Vector2, kind: int):
	for i in range(16):
		var n = Node3D.new()
		world.add_child(n)
		n.position = Vector3(where.x, 0.7, where.y)
		var theta = float(i) * TAU / 16.0
		var color = TRAP_COLORS[kind] if i % 3 == 0 else ("#f7d36e" if i % 2 == 0 else "#fcf8e1")
		ball(n, "ComicSpark", Vector3.ZERO, 0.07 + float(i % 3) * 0.03, color)
		prank_particles.append({"node": n, "velocity": Vector3(cos(theta) * (1.1 + i % 3), 1.5 + float(i % 4) * 0.3, sin(theta) * (1.1 + i % 3)), "life": 1.5})

func finish_trap(t, e):
	t["armed"] = false
	t["used"] = true
	t["glow"].visible = false
	t["node"].scale = Vector3(1.5, 0.25, 1.5)
	e["stun"] = 2.9
	e["alert"] = 0.0
	e["mode"] = "react"
	e["reaction"] = int(t["kind"])
	score += 1
	combo = combo + 1 if combo_timer > 0.0 else 1
	combo_timer = 20.0
	var award = 100 + (combo - 1) * 40
	prank_points += award
	effect_pos = t["pos"]
	effect_type = t["kind"]
	effect_time = 1.6
	spawn_comic_burst(t["pos"], int(t["kind"]))
	sound(sfx_prank)
	tell(PRANK_LINES[int(t["kind"])] + " +%d" % award)
	if score >= traps.size():
		episode_best = maxi(episode_best, prank_points)
		if level == 3: state = 4
		else:
			state = 2
			unlocked = maxi(unlocked, level + 1)
		var save = ConfigFile.new()
		save.load("user://pakosti_progress_3d.cfg")
		save.set_value("progress", "unlocked", unlocked)
		save.set_value("records", "level_%d" % level, episode_best)
		save.save("user://pakosti_progress_3d.cfg")
		sound(sfx_victory)

func clear_line(from: Vector2, to: Vector2) -> bool:
	for step in range(1, 10):
		var point = from.lerp(to, float(step) / 10.0)
		for wall in walls:
			if wall.grow(0.07).has_point(point):
				return false
	return true

func tick_enemy(e, dt: float):
	if e["stun"] > 0:
		e["stun"] = maxf(0.0, float(e["stun"]) - dt)
		if e["mode"] == "react":
			var actor_root: Node3D = e["node"]
			actor_root.rotation.z = sin(game_time * 13.0) * 0.32 * minf(1.0, float(e["stun"]))
			actor_root.position.y = absf(sin(game_time * 10.0)) * 0.18
		if e["stun"] <= 0.0:
			e["node"].rotation.z = 0.0
			e["node"].position.y = 0.0
			e["mode"] = "patrol"
		return
	var pos: Vector2 = e["pos"]
	var to_player = player_pos - pos
	var distance = to_player.length()
	var face: Vector2 = e["face"]
	var seen = not player_hidden and distance < VISION[level] and to_player.normalized().dot(face) > 0.05 and safe_time <= 0 and clear_line(pos, player_pos)
	var nearby = not player_hidden and distance < 0.9 and safe_time <= 0
	if seen or nearby: e["alert"] = minf(1.0, float(e["alert"]) + dt * 1.4)
	else: e["alert"] = maxf(0, float(e["alert"]) - dt * 0.6)
	if float(e["alert"]) >= 0.9:
		e["mode"] = "chase"
		e["search"] = 3.4
	var route = e["route"]
	var target: Vector2
	var speed = NEIGHBOR_SPEEDS[level]
	if e["mode"] == "chase":
		if seen: e["search"] = 3.4
		else: e["search"] = float(e["search"]) - dt
		speed *= 1.6
		target = player_pos
		if float(e["search"]) <= 0 or player_hidden:
			e["mode"] = "patrol"
			e["alert"] = 0.0
	else:
		target = route[int(e["waypoint"])]
		if pos.distance_to(target) < 0.12:
			e["waypoint"] = (int(e["waypoint"]) + 1) % route.size()
			target = route[int(e["waypoint"])]
	var previous = pos
	e["path_timer"] = float(e["path_timer"]) - dt
	if e["path_timer"] <= 0.0 or e["path"].size() == 0:
		var from_cell = nearest_walkable(pos)
		var to_cell = nearest_walkable(target)
		e["path"] = navigation.get_point_path(from_cell, to_cell)
		e["path_timer"] = 0.48 if e["mode"] == "chase" else 1.25
	var route_path: PackedVector2Array = e["path"]
	while route_path.size() > 0 and pos.distance_to(route_path[0]) < 0.24:
		route_path.remove_at(0)
	e["path"] = route_path
	var steer = target
	if route_path.size() > 0: steer = route_path[0]
	var vector = steer - pos
	if vector.length_squared() > 0.003:
		var motion = vector.normalized() * minf(speed * dt, vector.length())
		var next = pos + Vector2(motion.x, 0)
		if not blocked(next): pos = next
		next = pos + Vector2(0, motion.y)
		if not blocked(next): pos = next
		if previous.distance_to(pos) > 0.003:
			e["face"] = (pos - previous).normalized()
	e["pos"] = pos
	e["node"].rotation.y = atan2((e["face"] as Vector2).x, (e["face"] as Vector2).y)
	set_actor_position(e["node"], pos)
	animate_avatar(e["node"], 1.0 if pos.distance_to(previous) > 0.005 else 0.0, game_time)
	for t in traps:
		if t["armed"] and not t["used"] and pos.distance_to(t["pos"]) < 0.5:
			finish_trap(t, e)
			return
	if not player_hidden and safe_time <= 0 and pos.distance_to(player_pos) < 0.45:
		lives -= 1
		caught_count += 1
		combo = 0
		combo_timer = 0.0
		sound(sfx_caught)
		player_pos = Vector2(-5.6, 2.2)
		safe_time = 2.5
		e["alert"] = 0
		e["mode"] = "patrol"
		tell("СОСЕД ПОЙМАЛ! ЖИЗНИ: %d" % lives)
		if lives <= 0: state = 3

func _process(dt):
	game_time += dt
	if state == 1 and not performance_mode and not quality_selected:
		performance_clock += dt
		performance_frames += 1
		if performance_clock >= 4.0:
			if performance_frames / performance_clock < 24.0: set_performance_mode(true)
			performance_clock = 0.0
			performance_frames = 0
	message_timer = maxf(0, message_timer - dt)
	effect_time = maxf(0, effect_time - dt)
	combo_timer = maxf(0.0, combo_timer - dt)
	var live_effects = []
	for dot in prank_particles:
		dot["life"] = float(dot["life"]) - dt
		if dot["life"] > 0:
			var n: Node3D = dot["node"]
			n.position += dot["velocity"] * dt
			dot["velocity"] = dot["velocity"] + Vector3(0, -4.8 * dt, 0)
			n.scale = Vector3.ONE * minf(1.0, float(dot["life"]))
			live_effects.append(dot)
		else:
			dot["node"].queue_free()
	prank_particles = live_effects
	if is_instance_valid(camera_3d):
		var target = Vector3(clampf(player_pos.x * 0.68, -3.1, 3.1), 0.0, clampf(player_pos.y * 0.68, -2.05, 2.05))
		camera_focus = camera_focus.lerp(target, minf(1.0, dt * 2.4))
		camera_3d.position = camera_focus + camera_offset
		camera_3d.look_at(camera_focus, Vector3.UP)
	tapping_timer = maxf(0.0, tapping_timer - dt)
	if state == 1:
		episode_time += dt
		move_player(dt)
		safe_time = maxf(0, safe_time - dt)
		for e in enemies:
			if state != 1: break
			tick_enemy(e, dt)
		for item in supply_items:
			if not item["taken"]:
				var marker: Node3D = item["node"]
				marker.rotation.y += dt * 1.5
				marker.position.y = 0.11 + sin(game_time * 3.7 + item["kind"]) * 0.07
		for t in traps:
			var node: Node3D = t["node"]
			if t["armed"]:
				node.rotation.y += dt
				node.position.y = 0.08 + sin(game_time * 5.0) * 0.05
			elif not t["used"]:
				node.position.y = 0.08 + sin(game_time * 2.8) * 0.025
	if is_instance_valid(hud): hud.queue_redraw()

func attach_prop(parent: Node3D, kind: int, halo: Node3D):
	if not is_instance_valid(imported_world): return
	var template = imported_world.find_child("Prop%d" % kind, true, false)
	if not template is Node3D: return
	for old in parent.get_children():
		if old != halo: old.queue_free()
	var model = template.duplicate()
	parent.add_child(model)
	model.visible = true
	model.position = Vector3.ZERO

func set_performance_mode(enabled: bool):
	performance_mode = enabled
	get_viewport().scaling_3d_scale = 0.70 if enabled else 1.0
	var sun = get_node_or_null("SoftSun")
	if sun is DirectionalLight3D: sun.shadow_enabled = not enabled
	print("RENDER_QUALITY ", "smooth" if enabled else "detailed")
