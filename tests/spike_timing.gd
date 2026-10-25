extends SceneTree
func _initialize():
 var motion=load("res://scripts/world/room_features.gd")
 var failed=false;var previous=4.0;var largest=0.0
 for i in 601:
  var state=motion.spike_state(i/120.0,4.0)
  failed=failed or (state.active and state.height!=19.0)
  largest=maxf(largest,absf(state.height-previous));previous=state.height
 failed=failed or largest>2 or motion.spike_state(0,4).height!=4
 print("SPIKE_TIMING full_height_when_damaging=",not failed," largest_step=",largest)
 quit(1 if failed else 0)
