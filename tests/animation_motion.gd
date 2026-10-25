extends SceneTree
const M=preload("res://scripts/animation/hero_motion.gd")
var failures=0
func check(ok,label):
 if not ok:failures+=1;push_error(label)
 else:print("PASS ",label)
func _initialize():call_deferred("run")
func run():
 var stable=true
 for i in 100:
  var phase=float(i)/100*(M.SUPPORT-.001)*TAU;var p=M.sample("run",0,phase)
  var a=p.near_thigh.z;var b=p.near_shin.z
  var foot=Vector2(.265*sin(a)+.235*sin(a+b),.555+p.offset.y-.265*cos(a)-.235*cos(a+b))
  stable=stable and absf(foot.y-.055)<.0001 and absf(foot.x-lerpf(.25,-.25,phase/TAU/M.SUPPORT))<.0001
 check(stable,"support foot remains planted with fixed bone lengths")
 for n in 3:
  var a=M.ATTACKS[n];check(a.hit>0 and a.hit<a.duration,"attack impact inside clip "+str(n+1))
  var finite=true
  for fps in [30,60,120]:
   for i in ceili(a.duration*fps):
    var pose=M.sample("slash"+str(n+1),float(i)/fps)
    for key in pose:finite=finite and pose[key].is_finite()
  check(finite,"finite motion at 30/60/120 FPS "+str(n+1))
 var scene=load("res://scenes/animation/hero_rig.tscn").instantiate();root.add_child(scene)
 var skeleton=scene.get_node("HeroSkeleton");check(skeleton.get_bone_count()==17,"editable 17-bone rig")
 var player=scene.get_node("AnimationPlayer");check(player.get_animation_list().size()==12,"twelve reusable animation clips")
 player.play("run");player.advance(0);player.seek(.15,true);player.advance(0)
 check(absf(skeleton.get_bone_pose_rotation(skeleton.find_bone("near_thigh")).z)>.01,"exported AnimationPlayer drives actual skeleton")
 scene.queue_free();await process_frame;quit(1 if failures else 0)
