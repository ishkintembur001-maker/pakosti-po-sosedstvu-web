extends SceneTree
var failures=0
func check(ok:bool,message:String):
 if not ok:push_error(message);failures+=1
func _initialize():call_deferred("run")
func walk(g,dest:Vector2)->bool:
 g.player_path=g.path(g.player_pos,dest,g.floor_id)
 for frame in range(2000):
  g.action_time=maxf(0,g.action_time-1.0/60);g.move_player(1.0/60)
  if g.player_pos.distance_to(dest)<.25:return true
 print("WALK_FAIL destination=",dest," pos=",g.player_pos," remaining=",g.player_path);return false
func run():
 # Isolate QA progress from the user's normal save.
 var cfg=ConfigFile.new();var save=ProjectSettings.globalize_path("user://pakosti_release.cfg");var had=FileAccess.file_exists(save);var old=FileAccess.get_file_as_bytes(save) if had else PackedByteArray()
 var menu=load("res://scenes/release_menu.tscn").instantiate();root.add_child(menu);await process_frame
 menu.menu_action(1);var g=menu.active_game;g.set_process(false)
 for mission in range(8):
  g.start_case(mission)
  for item in g.supplies:
   check(walk(g,item.pos),"Supply unreachable in case %d kind %d"%[mission,item.kind]);g.act();check(item.taken and g.inventory[item.kind],"Pickup failed")
  if g.neighbor_floor==1:
   check(walk(g,Vector2(6.7,1.8)),"Stair entrance unreachable");g.act();check(g.climbing>0,"Stairs action failed")
   for frame in range(190):g._process(1.0/60)
   check(g.floor_id==1 and g.climbing<=0,"Stair transition failed");check(not g.blocked(g.player_pos,1),"Stair exit inside obstacle")
  for trap in g.targets:
   check(walk(g,trap.pos),"Trap unreachable in case %d"%mission);g.act();check(trap.armed,"Arming failed")
  # Exercise real patrol and trap collision; no direct finish_prank call.
  g.hidden=true;g.safe_time=999;var frames=0
  while g.state=="playing" and frames<24000:
   g.elapsed+=1.0/60;g.tick_enemy(1.0/60);frames+=1
  check(g.state=="won","Patrol did not trigger every trap in case %d"%mission)
  print("HOUSE_CASE_OK ",mission+1," simulated_frames=",frames)
 # Multitouch: action finger must not replace or release movement finger.
 g.start_case(0);g.handle_touch(0,Vector2(135,451),true);check(g.stick_id==0 and g.stick.x>.5,"Joystick start failed")
 g.handle_touch(1,Vector2(820,480),true);g.act();g.handle_touch(1,Vector2(820,480),false);check(g.stick_id==0 and g.stick.x>.5,"Second finger cancelled joystick")
 g.handle_touch(0,Vector2(100,451),false);check(g.stick==Vector2.ZERO,"Joystick release failed")
 g.floor_id=1;g.player_pos=Vector2(5,-2.15);g.act();for f in range(190):g._process(1.0/60)
 check(g.floor_id==0 and not g.blocked(g.player_pos,0),"Stair descent failed")
 menu.return_menu();check(menu.panel.visible and menu.active_game==null,"Return to menu failed")
 menu.music_level=.23;menu.sfx_level=.31;menu.save_settings();var saved=ConfigFile.new();saved.load(save);check(is_equal_approx(saved.get_value("audio","music",0),.23),"Audio settings not persisted")
 menu.start_classic();check(menu.active_game.state==1,"Classic launch failed");menu.return_menu()
 menu.queue_free();await process_frame;await process_frame
 if had:
  var file=FileAccess.open(save,FileAccess.WRITE);file.store_buffer(old);file.close()
 else:DirAccess.remove_absolute(save)
 print("HOUSE_QA_DONE failures=",failures);quit(1 if failures else 0)
