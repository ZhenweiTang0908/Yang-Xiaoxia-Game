extends SceneTree
var failed=0
func check(ok,label):
 if not ok:failed+=1;push_error(label)
 else:print("PASS ",label)
func _initialize():call_deferred("run")
func run():
 var rig=load("res://scripts/animation/hero_visual.gd").new();rig.preview=true;root.add_child(rig);rig.set_process(false)
 rig._process(0)
 check(rig.skin.mesh.get_surface_count()==1,"actual textured 2D mesh is rendered")
 check(rig.find_children("*","SubViewport",true,false).is_empty(),"no 3D viewport or replacement head")
 for state in ["idle","run","jump","fall","land","slash1","slash2","slash3","bow","roll"]:
  rig.preview_state=state
  var finite=true
  for i in 50:
   rig.preview_time=i/120.0;rig._process(1.0/120)
   for p in rig.current_targets:finite=finite and p.is_finite()
  check(finite,"finite 2D pose: "+state)
 rig.preview_state="jump";rig.preview_time=.07;rig._process(.2)
 var a=rig.current_targets.duplicate();rig.preview_time=.075;rig._process(.005)
 check(a[4].distance_to(rig.current_targets[4])>0.0001,"intermediate leg position changes between authored images")
 var before=rig.current_targets.duplicate();rig.preview_state="idle";rig._process(.001)
 check(before[0].distance_to(rig.current_targets[0])<.1,"state transition preserves collar position")
 var M=load("res://scripts/animation/hero_motion.gd")
 for i in 3:check(rig.attack_frame(M.ATTACKS[i].hit,i)==4,"strike frame matches damage time "+str(i+1))
 rig.queue_free();await process_frame;print("HERO_2D failures=",failed);quit(failed)
