extends SceneTree
func _initialize():call_deferred("run")
func run():
 var rig=load("res://scripts/animation/hero_visual.gd").new();rig.preview=true;root.add_child(rig);rig.set_process(false)
 var failures=0;var checked=0
 for state in ["slash1","slash2","slash3"]:
  rig.preview_state=state
  for sample in 20:
   rig.preview_time=sample*.02;rig._process(.02)
   var skin=rig.heavy_skin if state=="slash3" else rig.skin
   var actual=skin.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
   for tri in range(0,skin.indices.size(),93):
    var a=skin.indices[tri];var b=skin.indices[tri+1];var c=skin.indices[tri+2]
    var rest=(skin.rest[a]+skin.rest[b]+skin.rest[c])/3
    var expected=(actual[a]+actual[b]+actual[c])/3
    if skin.surface_point(rest).distance_to(Vector2(expected.x,expected.y))>.001:failures+=1
    checked+=1
   if not skin.weapon_socket(true).is_finite():failures+=1
 print("BLADE_SURFACE triangles=",checked," failures=",failures)
 rig.queue_free();await process_frame;quit(failures)
