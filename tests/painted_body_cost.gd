extends SceneTree
func _initialize():call_deferred("run")
func run():
 var rig=load("res://scripts/animation/painted_rig/combo.gd").new();root.add_child(rig);rig.set_process(false);rig.attack_index=-1
 for mode in ["idle","run"]:
  var samples=[]
  rig.motion_amount=0 if mode=="idle" else 1
  for i in 125:
   rig.age=i/60.0;rig.sampled_pose=rig.pose_transforms()
   var start=Time.get_ticks_usec()
   rig.update_secondary(1.0/60)
   rig.update_body_surface()
   var elapsed=(Time.get_ticks_usec()-start)/1000.0
   if i>=5:samples.append(elapsed)
  samples.sort()
  print("BODY_COST mode=",mode," median_ms=",samples[60]," p95_ms=",samples[114])
 rig.queue_free();await process_frame;quit()
