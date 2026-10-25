extends SceneTree
func _initialize():call_deferred("run")
func run():
 var rig=load("res://scripts/animation/hero_visual.gd").new();rig.preview=true;root.add_child(rig);rig.set_process(false)
 var errors=0;var leg_vertices=0
 for frame in range(10,16):
  rig.skin.prepare(frame)
  for i in rig.skin.rest.size():
   var weight=rig.skin.weights[i][6]+rig.skin.weights[i][7]
   if rig.skin.rest[i].y<=rig.skin.points[1].y and weight>.00001:errors+=1
   if weight>.5:leg_vertices+=1
  var original=rig.skin.points.duplicate();rig.skin.render_pose(frame,original)
  var before=rig.skin.rendered_points.duplicate();var moved=original.duplicate();moved[6].x+=1
  rig.skin.render_pose(frame,moved)
  for i in rig.skin.rest.size():
   if rig.skin.rest[i].y<=rig.skin.points[1].y and before[i].distance_to(rig.skin.rendered_points[i])>.00001:errors+=1
 if leg_vertices<12:errors+=1
 print("KNEE_INFLUENCE leg_vertices=",leg_vertices," errors=",errors)
 rig.queue_free();await process_frame;quit(errors)
