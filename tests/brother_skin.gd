extends SceneTree
var failed=0
func check(ok,label):
 if not ok:failed+=1;push_error(label)
 else:print("PASS ",label)
func _initialize():call_deferred("run")
func run():
 var art=load("res://scripts/actors/atlas_actor.gd").new();root.add_child(art);art.configure("res://assets/art/v3/niu_human.png",6,4,88)
 var visual=load("res://scripts/animation/brother_visual.gd").new();visual.preview=true;visual.source_art=art;root.add_child(visual);visual.set_process(false)
 check(art.texture.resource_path.ends_with("v3/niu_human.png"),"original brother artwork retained")
 for frame in [0,6,14,18,19,21,22]:
  visual.preview_frame=frame;visual._process(1.0/60)
  var good=true
  for i in visual.rest.size():
   var p=visual.deform(visual.rest[i],visual.weights[i]);good=good and p.is_finite() and p.distance_to(visual.rest[i])<5
  check(good,"bounded continuous deformation frame "+str(frame))
 var feet_fixed=true
 for i in range(visual.rest.size()-19,visual.rest.size()):feet_fixed=feet_fixed and visual.deform(visual.rest[i],visual.weights[i]).is_equal_approx(visual.rest[i])
 check(feet_fixed,"foot baseline remains pinned")
 visual.queue_free();art.queue_free();await process_frame;print("BROTHER_SKIN failures=",failed);quit(failed)
