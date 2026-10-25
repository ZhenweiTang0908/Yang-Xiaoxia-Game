extends SceneTree
func _initialize():call_deferred("run")
func run():
 var rig=load("res://scripts/animation/hero_visual.gd").new();rig.preview=true;root.add_child(rig);rig.set_process(false)
 var failure=0;var max_motion=0.0
 for state in ["idle","run","jump","land","slash1","slash2","slash3"]:
  rig.preview_state=state
  for i in 40:
   rig.preview_time=i/120.0;rig._process(1.0/120)
   var skin=rig.heavy_skin if state=="slash3" else rig.skin
   max_motion=maxf(max_motion,skin.cloth_delta.length())
   if skin.cloth_delta.length()>.40001:failure+=1
   var after=skin.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
   skin.cloth_delta=Vector2.ZERO;skin.render_pose(skin.current,skin.target_points)
   var before=skin.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
   for j in skin.rest.size():
    var point=skin.rest[j]
    if point.y<=skin.points[0].y+4 or point.y>=skin.points[1].y+2:
     if before[j].distance_to(after[j])>.0001:
      if failure==0:print("FIRST ",state," point=",point," collar=",skin.points[0]," pelvis=",skin.points[1]," weight=",skin.cloth_weight(point)," difference=",before[j].distance_to(after[j]))
      failure+=1
 print("CLOTH_FOLLOW failures=",failure," maximum_displacement=",max_motion," head/collar/legs protected")
 rig.queue_free();await process_frame;quit(failure)
