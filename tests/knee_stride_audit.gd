extends SceneTree
func _initialize():call_deferred("run")
func run():
 var rig=load("res://tests/hero_stride_experiment.gd").new();rig.preview=true;rig.preview_state="run";root.add_child(rig);rig.set_process(false)
 var maximum=0.0
 for i in 240:
  rig._process(1.0/240)
  for leg in 2:
   var hip=rig.current_targets[1];var knee=rig.current_targets[6+leg];var foot=rig.current_targets[4+leg]
   maximum=maxf(maximum,maxf(absf(hip.distance_to(knee)-8.8),absf(knee.distance_to(foot)-8.8)))
 print("KNEE_STRIDE max_length_error=",maximum)
 rig.queue_free();await process_frame;quit()
