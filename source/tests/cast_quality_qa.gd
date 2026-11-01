extends SceneTree
var failures=0
func check(ok:bool,msg:String):
 if not ok:push_error(msg);failures+=1
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/house.tscn").instantiate();root.add_child(g);await process_frame;g.set_process(false)
 for actor in [g.hero,g.neighbor]:
  var faces=actor.find_children("*Face_Anatomy*","MeshInstance3D",true,false)
  check(faces.size()==1,"Anatomical face missing or duplicated")
  if faces.size()!=1:continue
  var face=faces[0];check(face.mesh.get_blend_shape_count()==3,"Missing facial shapes")
  var hair_id="GroomedHair_Hero" if actor==g.hero else "GroomedHair_Neighbor"
  var hair_meshes=actor.find_children("*"+hair_id+"*","MeshInstance3D",true,false)
  check(hair_meshes.size()==1,"Detailed hair sculpt missing or duplicated: "+hair_id)
  if hair_meshes.size()==1:
   check(hair_meshes[0].mesh.get_surface_count()>=2,"Hair lacks distinct sculpted tone materials")
  var expected=["Smile","Frown","Blink"]
  for i in range(face.mesh.get_blend_shape_count()):check(String(face.mesh.get_blend_shape_name(i)) in expected,"Unexpected facial target")
  g.elapsed=3.1;g.animate(actor,0,99);var smile=face.find_blend_shape_by_name("Smile")
  if actor==g.hero:check(face.get_blend_shape_value(smile)>.8,"Celebrate did not smile")
  g.elapsed=(5.7-3.1 if actor==g.neighbor else 5.7-1.7)+.09;g.animate(actor,0,0)
  check(face.get_blend_shape_value(face.find_blend_shape_by_name("Blink"))>.95,"Blink did not drive the eyelids")
  var material=face.get_active_material(0)
  check(material is StandardMaterial3D and material.vertex_color_use_as_albedo,"Complexion was not imported")
  print("ANATOMICAL_CAST_OK ",actor.name," shapes=",face.mesh.get_blend_shape_count())
 check(g.environment_root.find_child("*04_Upper_bedroom*",true,false)!=null,"Preserved upstairs room missing")
 g.queue_free();await process_frame
 var classic=load("res://scenes/main_3d.tscn").instantiate();root.add_child(classic);await process_frame;classic.set_process(false)
 for level in range(4):
  classic.start_level(level)
  var actors=[classic.actor]
  for enemy in classic.enemies:actors.append(enemy.node)
  for actor in actors:
   check(actor.find_children("*Face_Anatomy*","MeshInstance3D",true,false).size()==1,"Classic episode loaded an obsolete face")
  print("CLASSIC_CAST_OK level=",level+1)
 for player in classic.find_children("*","AudioStreamPlayer",true,false):player.stop()
 classic.queue_free();await process_frame;await create_timer(.2).timeout;print("CAST_QUALITY_QA failures=",failures);quit(1 if failures else 0)
