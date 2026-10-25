extends SceneTree
func _initialize():call_deferred("run")
func run():
 var rig=load("res://scripts/animation/hero_visual.gd").new();rig.preview=true;root.add_child(rig);rig.set_process(false)
 var checked=0;var failed=0
 for frame in range(10,16):
  rig.skin.prepare(frame)
  for i in rig.skin.rest.size():
   var p=rig.skin.rest[i]
   for foot in [4,5]:
    var anchor=rig.skin.points[foot]
    if absf(p.x-anchor.x)<=1.5 and p.y>=anchor.y-1 and p.y<=anchor.y+1:
     checked+=1
     if rig.skin.weights[i][foot]<.999:failed+=1
 if checked==0:failed+=1
 print("SOLE_SKINNING vertices=",checked," failures=",failed)
 rig.queue_free();await process_frame;quit(failed)
