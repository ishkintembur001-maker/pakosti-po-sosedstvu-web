extends SceneTree
var errors=0
func check(ok:bool,reason:String)->void:
 if not ok:push_error(reason);errors+=1
func _initialize()->void:call_deferred("run")
func run()->void:
 for item in ["menu_jazz","mission_sneak","mission_chase"]:
  var resource="res://assets/music/"+item+".ogg"
  check(ResourceLoader.exists(resource),"Music absent: "+resource)
  var stream=load(resource) as AudioStream
  check(stream!=null and stream.get_length()>10.0,"Music invalid "+resource)
 for n in range(1,4):
  var resource="res://assets/voices/caught_%d.ogg"%n
  check(ResourceLoader.exists(resource),"Voice absent "+resource)
  var stream=load(resource) as AudioStream
  check(stream!=null and stream.get_length()>.3,"Voice invalid "+resource)
 var menu=load("res://scenes/release_menu.tscn").instantiate()
 root.add_child(menu);await process_frame
 check(menu.music.playing,"Menu music did not start")
 check(menu.menu_progress!=null and menu.desktop_card!=null,"Desktop interface missing")
 menu.start_house(0);await process_frame
 var game=menu.active_game
 game.set_process(false)
 check(menu.mission_theme.playing and menu.chase_theme.playing,"Mission layers not active")
 var supply=game.supplies[0]
 var screen=game.camera.unproject_position(Vector3(supply.pos.x,.55,supply.pos.y))
 var mouse=InputEventMouseButton.new();mouse.button_index=MOUSE_BUTTON_LEFT;mouse.pressed=true;mouse.position=screen
 game._unhandled_input(mouse)
 check(game.pending_action=="interact","Windows mouse click failed to choose pickup")
 game.safe_time=0;game.begin_capture()
 check(game.neighbor_voice.playing and not game.capture_voice_caption.is_empty(),"Caught voice did not play")
 game.hud.show_pause()
 check(game.paused,"Mouse-accessible pause did not freeze game")
 menu.return_menu();await process_frame
 check(menu.panel.visible and not menu.mission_theme.playing,"Return to desktop menu failed")
 menu.queue_free();await process_frame
 print("DESKTOP_MOUSE_AUDIO_QA errors=",errors);quit(errors)
