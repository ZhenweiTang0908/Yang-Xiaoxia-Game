extends SceneTree
func _initialize():call_deferred("run")
func run():
 var rig=load("res://scripts/animation/hero_visual.gd").new();rig.preview=true;root.add_child(rig);rig.set_process(false);rig.preview_state="land"
 var worst=-100.0
 for i in 22:
  rig.preview_time=i/120.0;rig._process(1.0/120)
  if rig.skin.current==35:worst=maxf(worst,rig.skin.weapon_socket(true).y)
 print("LAND_BLADE maximum_tip_y=",worst)
 rig.queue_free();await process_frame;quit(0 if worst<0 else 1)
