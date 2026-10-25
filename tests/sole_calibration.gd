extends SceneTree
func _initialize():call_deferred("run")
func run():
 var rig=load("res://scripts/animation/hero_visual.gd").new();rig.preview=true;root.add_child(rig);rig.set_process(false)
 for frame in [0,10,11,12,13,14,15,16,20,24,28,31,35]:
  print(frame," old=",rig.skin.GUIDES.guides(frame)[4][1],",",rig.skin.GUIDES.guides(frame)[5][1]," actual=",rig.skin.sole_positions(frame))
 rig.queue_free();await process_frame;quit()
