extends SceneTree

func _initialize():
	call_deferred("verify_episode")

func fail(message: String):
	push_error("EPISODE_TEST_FAILED: " + message)
	quit(1)

func verify_episode():
	var packed = load("res://scenes/main_3d.tscn")
	if packed == null:
		fail("3D scene not found")
		return
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame
	game.start_level(0)
	if game.imported_world == null:
		fail("Detailed Blender apartment did not import")
		return
	if not game.actor.has_meta("high_detail"):
		fail("New detailed hero model not active")
		return
	if not game.enemies[0]["node"].has_meta("high_detail"):
		fail("New detailed neighbor model not active")
		return
	print("PREMIUM_GLTF_APARTMENT_AND_CAST_OK")
	if game.traps.size() != 3 or game.supply_items.size() != 3:
		fail("First episode must have 3 unique pranks")
		return
	if game.state != 1:
		fail("Episode must be playable")
		return

	if game.navigation == null:
		fail("Navigation grid was not created")
		return
	game.plan_walk(Vector2(-5.35, 1.15))
	if not game.auto_move or game.walk_path.size() < 1:
		fail("Tap-to-move did not calculate walkable route")
		return
	game.touch_joystick(game.STICK_CENTER + Vector2(game.STICK_RADIUS, 0))
	if game.joystick_vector().x < 0.95:
		fail("Analog joystick cannot reach full strength")
		return
	var before: Vector2 = game.player_pos
	game.move_player(0.1)
	if game.auto_move or game.player_pos.distance_to(before) < 0.03:
		fail("Direct joystick did not override auto route and move hero")
		return
	game.stick_motion = Vector2.ZERO
	game.player_pos = Vector2(-5.6, 2.2)
	game.plan_walk(Vector2(-4.25, 2.95))
	if game.walk_path.size() < 1:
		fail("Second tap route is unreachable in starter room")
		return
	game.auto_move = false
	game.walk_path = PackedVector2Array()
	var trap = game.traps[0]
	game.player_pos = trap["pos"]
	game.on_action()
	if trap["armed"]:
		fail("Cannot set a trap without collecting its item")
		return
	for item in game.supply_items:
		var kind: int = item["kind"]
		game.player_pos = item["pos"]
		game.on_action()
		if not game.inventory[kind] or not item["taken"]:
			fail("Item pickup did not update inventory")
			return
		var t = game.traps[kind]
		game.player_pos = t["pos"]
		game.on_action()
		if not t["armed"] or game.inventory[kind]:
			fail("Placing a trap failed or inventory was not consumed")
			return
		game.finish_trap(t, game.enemies[0])
		if not t["used"]:
			fail("Prank not recorded")
			return
	if game.score != 3 or game.state != 2 or game.unlocked < 1:
		fail("First episode victory or unlock failed")
		return
	if game.prank_points < 300:
		fail("Score system did not award points")
		return
	game.start_level(1)
	game.player_pos = game.CLOSSETS[0] + Vector2(0.68, 0.0)
	game.on_action()
	if not game.player_hidden:
		fail("Hiding in closet must work")
		return
	game.on_action()
	if game.player_hidden:
		fail("Exiting closet must work")
		return
	game.start_level(3)
	if game.traps.size() != 4 or game.enemies.size() != 2:
		fail("Final episode must include 4 pranks and 2 neighbors")
		return
	for sound in [game.sfx_pickup,game.sfx_arm,game.sfx_prank,game.sfx_caught,game.sfx_victory]: sound.stop()
	game.queue_free()
	await process_frame
	await process_frame
	print("EPISODE_3D_GAMEPLAY_OK: inventory, placement, score, win, hiding and final episode")
	await create_timer(0.15).timeout
	quit(0)
