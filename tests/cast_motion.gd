extends SceneTree
var failures=0
func check(ok,label):
 if not ok:failures+=1;push_error(label)
 else:print("PASS ",label)
func _initialize():call_deferred("run")
func run():
 var rig=load("res://scripts/animation/cast_visual.gd").new();rig.preview=true;rig.species="bull";rig.height=62;root.add_child(rig);rig.set_process(false)
 var reference={}
 for fps in [30,60,120]:
  rig.clock=0;rig.phase=0;rig.age=0;rig.state="idle";rig.eye_history.clear();rig.position=Vector2.ZERO;rig.preview_state="run";rig.preview_speed=100
  for i in fps:
   rig.position.x+=100.0/fps;rig._process(1.0/fps)
  var position=rig.model.skeleton.get_bone_global_pose(rig.model.bones.near_front_lower).origin
  if fps==30:reference.position=position
  check(position.distance_to(reference.position)<.001,"gait matches at "+str(fps)+" FPS")
  check(rig.eye_history.size()<=18,"bounded eye history at "+str(fps)+" FPS")
  var at=rig.to_global(rig.eye_point());var bounded=true
  for point in rig.eye_history:bounded=bounded and point.at.distance_to(at)<=13.01
  check(bounded,"eye trail stays short at "+str(fps)+" FPS")
 rig.preview_speed=0
 for i in 20:rig._process(1.0/60)
 check(rig.eye_history.is_empty(),"eye trail expires after stopping")
 rig.preview_speed=100;rig._process(.016);rig.position.x+=300;rig._process(.016)
 check(rig.eye_history.size()==1,"teleport clears connecting trail")
 rig.facing=-1;rig._process(.016);check(rig.eye_history.size()==1,"turn clears previous eye direction")
 rig.queue_free();await process_frame;print("CAST_MOTION failures=",failures);quit(failures)
