extends SceneTree
var failures=0
func check(ok:bool,reason:String)->void:
 if not ok:
  failures+=1
  push_error("OWNER_MODEL_QA_FAIL: "+reason)
func _initialize()->void:call_deferred("run")
func run()->void:
 if not preload("res://scripts/user_models_integration.gd").available():
  print("OWNER_MODEL_QA_SKIPPED: no model pack")
  quit(0)
  return
 var game=load("res://scenes/house.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 check(game.get_meta("user_models_installed",false),"Original user GLBs were not integrated")
 check(game.CASES.size()==24,"24 missions were lost")
 check(game.navs.size()==2,"Two navigable floors were lost")
 game._process(0)
 var h=game.hero.find_child("OwnersHighDetailHero",true,false)
 var n=game.neighbor.find_child("OwnersHighDetailNeighbor",true,false)
 var scan=preload("res://scripts/user_models_integration.gd")
 if FileAccess.file_exists(scan.SCAN_SURFACE) and FileAccess.file_exists(scan.SCAN_OBSTACLES):
  scan.update_visual_grounding(game)
  check(absf(h.position.x)<.68 and absf(h.position.z)<.68,"Hero mesh correction is too large")
  check(absf(n.position.x)<.68 and absf(n.position.z)<.68,"Neighbor mesh correction is too large")
 check(h!=null and h.position.y>1.0,"Lower-floor hero feet are buried in the scan")
 check(n!=null and n.position.y>1.0,"Lower-floor neighbor feet are buried in the scan")
 check(h!=null,"User hero GLB not installed")
 check(n!=null,"User neighbor GLB not installed")
 var building=game.find_child("OwnersHighDetailTwoStoreyHouse",true,false)
 check(building!=null,"User house not installed")
 if building!=null:
  check(building.find_child("HouseGroundFloor",true,false)!=null,"First floor missing")
  var upper=building.find_child("HouseSecondFloor",true,false)
  check(upper!=null and upper.visible,"Second floor must be present and visible")
  check(building.find_child("HouseRoof",true,false)!=null,"Roof missing")
 check(not game.environment_root.visible,"Old house overlaps the new scan")
 var hp=game.hero.get_meta("animation_player") as AnimationPlayer
 var np=game.neighbor.get_meta("animation_player") as AnimationPlayer
 check(hp!=null and hp.has_animation("walk"),"Hero walk clip missing")
 check(np!=null and np.has_animation("walk"),"Neighbor walk clip missing")
 check(hp!=null and hp.has_animation("caught_react") and not hp.has_animation("catch"),"Hero must only react defensively")
 check(np!=null and np.has_animation("catch") and not np.has_animation("caught_react"),"Neighbor must initiate capture")
 for mission in range(24):
  game.start_case(mission)
  check(game.targets.size()>=4 and game.targets.size()<=8,"Mission %d incomplete"%(mission+1))
 var integration=preload("res://scripts/user_models_integration.gd")
 if FileAccess.file_exists(integration.SCAN_SURFACE) and FileAccess.file_exists(integration.SCAN_OBSTACLES):
  for floor_index in range(2):
   for location in [Vector2(-4.7,1.0),Vector2(-1.1,1.1),Vector2(2.2,1.1)]:
    game.player_pos=location;game.floor_id=floor_index
    game.hero.position=Vector3(location.x,game.floor_height(location,floor_index)-.015,location.y)
    for repeat in range(12):integration.update_visual_grounding(game)
    var visible_hero=game.hero.find_child("OwnersHighDetailHero",true,false)
    var floor_y=integration._scan_height(game,location,floor_index)
    var feet=game.hero.position.y+visible_hero.position.y-.951712*.84
    check(absf(feet-floor_y)<.07,"Hero feet float on floor %d at %s"%[floor_index,str(location)])
  check(not game.clear_line(Vector2(-4.1,1.1),Vector2(-3.0,1.1),0),"Neighbor sees through owner scan wall")
  check(game.clear_line(Vector2(-5.3,1.1),Vector2(-4.25,1.1),0),"Clear room blocks neighbor vision")
 print("OWNER_MODEL_QA_DONE failures=",failures)
 game.queue_free()
 await process_frame
 await process_frame
 quit(1 if failures else 0)
