extends SceneTree
func _initialize():call_deferred("run")
func run():
 var rig=load("res://scripts/animation/hero_visual.gd").new()
 rig.preview=true;root.add_child(rig);rig.set_process(false)
 rig.preview_state="run";rig.preview_ground=true
 var failure=0
 for rate in [30,60,120]:
  rig.run_phase=0;rig.state_age=1
  for i in rate*2:
   rig._process(1.0/rate)
   var feet=maxf(rig.current_targets[4].y,rig.current_targets[5].y)
   if absf(feet)>.0001:failure+=1
  print("CHECK grounded run at ",rate," FPS")
 # Compare with an airborne preview at the identical phase: all six anchors
 # must receive exactly the same translation, preserving face/neck proportions.
 rig.preview_ground=false;rig._process(0)
 var floating=rig.current_targets.duplicate()
 rig.preview_ground=true;rig._process(0)
 var shift=rig.current_targets[0]-floating[0]
 for i in 6:
  if (rig.current_targets[i]-floating[i]).distance_to(shift)>.0001:failure+=1
 print("RUN_SUPPORT failures=",failure)
 rig.queue_free();await process_frame;quit(failure)
