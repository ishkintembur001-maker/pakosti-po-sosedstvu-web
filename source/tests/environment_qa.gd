extends SceneTree
var failures=0
func check(ok:bool,msg:String):
 if not ok:push_error(msg);failures+=1
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/house.tscn").instantiate();root.add_child(g);await process_frame;g.set_process(false)
 check(not g.floor_data.is_empty(),"Baked floor heights missing")
 check(g.floor_height(Vector2(5.5,1.1),0)>.18 and g.floor_height(Vector2(5.5,1.1),0)<.23,"Wood floor height incorrect")
 check(g.floor_height(Vector2(-5,1.1),0)>.29,"Rug must be above wood floor")
 var mapped=0;var normals=0
 for material in g.slice_materials:
  if material.get_shader_parameter("ao_mapped"):
   mapped+=1;check(material.get_shader_parameter("ao_tex").get_width()==1024,"Unexpected house AO atlas")
  if material.get_shader_parameter("normal_mapped"):normals+=1
 check(mapped>=60,"Cutaway shader lost baked occlusion")
 check(normals>=5,"PBR normal maps did not reach the renderer")
 g.player_pos=Vector2(-5,1.1);g._process(0)
 check(absf(g.hero.position.y+.015*g.hero.scale.y-g.floor_height(g.player_pos,0))<.002,"Hero penetrates the rug")
 check(absf(g.hero_contact.position.y-g.floor_height(g.player_pos,0)-.004)<.002,"Contact shadow does not sit on the floor")
 g.hidden=true;g._process(0);check(not g.hero_contact.visible,"Hidden hero left a visible shadow")
 g.set_quality(false)
 for material in g.slice_materials:
  check(material.get_shader_parameter("detail_normals")==false,"Smooth preset must disable detail normal sampling")
  check(material.get_shader_parameter("ao_mapped"),"Smooth preset lost contact shading")
 print("HOUSE_ENVIRONMENT_OK ao_surfaces=",mapped," normal_surfaces=",normals)
 g.queue_free();await process_frame
 var classic=load("res://scenes/main_3d.tscn").instantiate();root.add_child(classic);await process_frame;classic.set_process(false)
 var classic_ao=0
 for mesh in classic.imported_world.find_children("*","MeshInstance3D",true,false):
  for i in range(mesh.mesh.get_surface_count()):
   var material=mesh.get_active_material(i)
   if material is StandardMaterial3D and material.ao_enabled and material.ao_texture:
    classic_ao+=1;check(material.ao_on_uv2,"Classic AO must use its own UV atlas")
 check(classic_ao>=10,"Classic environment did not receive baked shading")
 print("CLASSIC_ENVIRONMENT_OK ao_surfaces=",classic_ao)
 for player in classic.find_children("*","AudioStreamPlayer",true,false):player.stop()
 classic.queue_free();await process_frame;await create_timer(.2).timeout
 print("ENVIRONMENT_QA failures=",failures);quit(1 if failures else 0)
