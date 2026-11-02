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
 var launch_touch=InputEventScreenTouch.new();launch_touch.index=0;launch_touch.position=Vector2(200,257);launch_touch.pressed=true;menu._input(launch_touch)
 check(is_instance_valid(menu.active_game),"Menu screen touch did not launch game")
 var g=menu.active_game;g.set_process(false)
 check(g.CASES.size()==24,"Expected 24 playable campaign missions")
 for level in range(24):
  g.start_case(level)
  check(g.targets.size()>=4 and g.targets.size()<=8,"Expected 4–8 pranks per mission")
  check(g.targets.size()==g.supplies.size(),"Each prank needs a corresponding item")
  check(g.CASES[level].tasks.size()==g.targets.size(),"Mission blueprint and active targets mismatch")
  for trap_prop in g.targets:
   var prop=trap_prop.node.find_child("PrankProp",true,false)
   check(is_instance_valid(prop),"Missing 3D prank prop")
   if is_instance_valid(prop):check(int(prop.get_meta("family",-1))==int(trap_prop.kind),"Wrong 3D prank prop")
  check(g.bonus_description().length()>0,"Bonus rule lacks a truthful description")
  check(String(g.CASES[level].id)=="m%02d"%(level+1),"Mission id invalid")
  var unique_slots={}
  for trap in g.targets:
   check(not unique_slots.has(trap.pos),"Duplicate target in mission")
   unique_slots[trap.pos]=true
   check(not g.path(g.player_pos,trap.pos,int(trap.floor)).is_empty(),"Trap location unreachable")
   check(not String(trap.label).is_empty(),"Mission target lacks specific description")
  for supply in g.supplies:
   check(not g.path(g.player_pos,supply.pos,0).is_empty(),"Supply unreachable in case %d"%level)
  for trap in g.targets:g.finish_prank(trap)
  check(g.escape_ready and g.anger_events==g.targets.size(),"Mission cannot complete its own tasks")
  check(g.particles.size()<=112,"Unbounded temporary effects")
  check(g.targets.all(func(trap):return trap.used),"Mission reaction count mismatch")
 # Full end-to-end playability: all 24, including walking, collecting, stairs,
 # arming, actual neighbor patrol reactions and safe exit.
 for mission in range(24):
  g.start_case(mission)
  for item in g.supplies:
   check(walk(g,item.pos),"Supply unreachable in case %d kind %d"%[mission,item.kind]);g.act();check(item.taken and g.inventory[item.kind]>0,"Pickup failed")
  if g.neighbor_floor==1:
   check(walk(g,Vector2(6.7,1.8)),"Stair entrance unreachable");g.act();check(g.climbing>0,"Stairs action failed")
   for frame in range(190):g._process(1.0/60)
   check(g.floor_id==1 and g.climbing<=0,"Stair transition failed");check(not g.blocked(g.player_pos,1),"Stair exit inside obstacle")
  for trap in g.targets:
   check(walk(g,trap.pos),"Trap unreachable in case %d"%mission);g.act();check(trap.armed,"Arming failed")
  # Exercise real patrol and trap collision; no direct finish_prank call.
  g.hidden=true;g.safe_time=999;var frames=0
  while not g.escape_ready and frames<24000:
   g.elapsed+=1.0/60;g.tick_enemy(1.0/60);frames+=1
  check(g.escape_ready,"Patrol did not trigger every trap in case %d"%mission)
  check(g.anger_events==g.targets.size(),"Neighbor anger must increase after each prank")
  g.guide_to_exit()
  for step in range(1800):
   if g.state!="playing":break
   g._process(1.0/60)
  check(g.state=="won","Failed to navigate to the safe exit in case %d"%mission)
  print("HOUSE_CASE_OK ",mission+1," simulated_frames=",frames)
 # One touch chooses a goal and walks to collect it, without a joystick.
 if is_instance_valid(g.hud.result):g.hud.result.free();g.hud.result=null
 g.start_case(0);g._process(0)
 var supply=g.supplies[0]
 var screen=g.camera.unproject_position(Vector3(supply.pos.x,.55,supply.pos.y))
 var touch=InputEventScreenTouch.new();touch.index=0;touch.position=screen;touch.pressed=true
 g._unhandled_input(touch)
 check(g.pending_action=="interact","One-tap pickup did not set automatic interaction")
 for frame in range(650):g.action_time=maxf(0,g.action_time-1.0/60);g.move_player(1.0/60)
 check(supply.taken,"One-tap pickup did not collect the item")
 for mission in range(8,24):
  g.start_case(mission)
  check(g.targets.size()==g.supplies.size() and g.targets.size()>0,"New challenge has no playable targets")
 check(not g.hud.action.visible,"Exit button shown before all traps complete")
 g.start_case(0);g.safe_time=0;g.begin_capture()
 check(g.capture_time>0 and g.lives==2,"Capture must cost a life and start scene")
 g.tick_capture(.04)
 var hero_anim=g.hero.get_meta("animation_player") as AnimationPlayer
 var neighbor_anim=g.neighbor.get_meta("animation_player") as AnimationPlayer
 check(hero_anim!=null and hero_anim.current_animation=="caught_react","Hero must ONLY react defensively to neighbor capture")
 check(neighbor_anim!=null and neighbor_anim.current_animation=="catch","Only the neighbor must perform capture")
 for frame in range(120):g.tick_capture(1.0/60)
 check(g.capture_time==0 and g.player_pos==g.EXIT_POS,"Hero must respawn after capture")
 # A neighbor who spotted the hero must use the staircase to follow across floors.
 g.start_case(9)
 g.neighbor_floor=1;g.neighbor_pos=Vector2(5.0,-2.15)
 g.floor_id=0;g.player_pos=Vector2(4.2,1.1)
 g.enemy_search_time=8.0;g.alert=1.0
 g.tick_enemy(1.0/60)
 check(g.enemy_climbing>0,"Neighbor did not start descending the staircase")
 g.tick_enemy(1.0)
 check(g.neighbor_stair_world.y>0.2 and g.neighbor_stair_world.y<g.H+.2,"Neighbor must move physically between floors")
 for step in range(140):g.tick_enemy(1.0/60)
 check(g.enemy_climbing==0 and g.neighbor_floor==0,"Neighbor must finish stair descent")
 g.start_case(0)
 g.neighbor_floor=0;g.neighbor_pos=Vector2(6.7,1.8)
 g.floor_id=1;g.player_pos=Vector2(5.0,-2.15)
 g.enemy_search_time=8.0;g.alert=1.0
 g.tick_enemy(1.0/60)
 check(g.enemy_climbing>0,"Neighbor did not start ascending the staircase")
 for step in range(190):g.tick_enemy(1.0/60)
 check(g.enemy_climbing==0 and g.neighbor_floor==1,"Neighbor must finish stair ascent")
 # Validate full pathfinding to the stair entrances, not just stair animation.
 g.start_case(9)
 g.neighbor_floor=1;g.neighbor_pos=Vector2(-4.1,1.1)
 g.floor_id=0;g.player_pos=Vector2(4.2,1.1)
 g.enemy_search_time=16;g.alert=1.0;g.enemy_path.clear()
 var actually_descended=false
 for frame in range(1350):
  g.tick_enemy(1.0/60)
  if g.neighbor_floor==0:
   actually_descended=true;break
 check(actually_descended,"Neighbor could not navigate from upper patrol corridor to downstairs")
 g.start_case(0)
 g.neighbor_floor=0;g.neighbor_pos=Vector2(-4.1,1.1)
 g.floor_id=1;g.player_pos=Vector2(5.0,-2.15)
 g.enemy_search_time=16;g.alert=1.0;g.enemy_path.clear()
 var actually_ascended=false
 for frame in range(1350):
  g.tick_enemy(1.0/60)
  if g.neighbor_floor==1:
   actually_ascended=true;break
 check(actually_ascended,"Neighbor could not navigate from lower patrol corridor to upstairs")
 g.start_case(0);check(g.particles.is_empty(),"Temporary prank effects leaked between levels")
 g.caught=0;check(g.qualifies_bonus(),"No-capture bonus should count")
 g.caught=1;check(not g.qualifies_bonus(),"No-capture bonus should fail after capture")
 g.floor_id=1;g.player_pos=Vector2(5,-2.15);g.act();for f in range(190):g._process(1.0/60)
 check(g.floor_id==0 and not g.blocked(g.player_pos,0),"Stair descent failed")
 menu.return_menu();check(menu.panel.visible and menu.active_game==null,"Return to menu failed")
 menu.music_level=.23;menu.sfx_level=.31;menu.save_settings();var saved=ConfigFile.new();saved.load(save);check(is_equal_approx(saved.get_value("audio","music",0),.23),"Audio settings not persisted")
 menu.start_classic();check(menu.active_game.state==1,"Classic launch failed");menu.return_menu()
 menu.queue_free();await process_frame;await process_frame
 if had:
  var file=FileAccess.open(save,FileAccess.WRITE);file.store_buffer(old);file.close()
 else:DirAccess.remove_absolute(save)
 await create_timer(.2).timeout
 print("HOUSE_QA_DONE failures=",failures);quit(1 if failures else 0)
