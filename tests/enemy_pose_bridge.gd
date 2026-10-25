extends SceneTree
var failed=0
func check(ok,label):
 if ok:print("PASS ",label)
 else:failed+=1;push_error(label)
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.start_new(false)
 var enemy=game.enemies[0];enemy.set_physics_process(false);enemy.art.set_process(false)
 enemy.kind="pouncer";enemy.body_height=46;enemy.art.scale_unit=46.0/enemy.art.bounds[18].size.y
 enemy.art.frame=20;enemy.art.update_pose_mesh()
 var anticipation=enemy.art.displayed.duplicate()
 enemy.art.frame=21;enemy.art.update_pose_mesh()
 check(enemy.art.bridge_left>0,"pounce release starts a continuous bridge")
 check(enemy.art.displayed==anticipation,"release begins at the last displayed silhouette")
 check(enemy.art.mesh.get_surface_count()==1,"transition draws one enemy mesh")
 var previous=enemy.art.displayed.duplicate();var max_step=0.0
 for step in 8:
  enemy.art._process(1.0/120.0);enemy.art.update_pose_mesh()
  for i in enemy.art.displayed.size():max_step=maxf(max_step,previous[i].distance_to(enemy.art.displayed[i]))
  previous=enemy.art.displayed.duplicate()
 check(enemy.art.bridge_left==0,"pounce release bridge finishes")
 check(max_step<14,"pounce bridge has bounded per-frame motion")
 var target=enemy.art.posed_vertices();var error=0.0
 for i in target.size():error=maxf(error,target[i].distance_to(enemy.art.displayed[i]))
 check(error<.001,"bridge lands exactly on the authored attack pose")
 for fps in [30,60,120]:
  enemy.art.frame=20;enemy.art.update_pose_mesh();enemy.art.bridge_left=0;enemy.art.update_pose_mesh()
  enemy.art.frame=21;enemy.art.update_pose_mesh()
  var dt=1.0/fps;var last=enemy.art.displayed.duplicate();var fps_step=0.0
  for step in ceili(enemy.art.bridge_duration/dt)+1:
   enemy.art._process(dt);enemy.art.update_pose_mesh()
   for i in enemy.art.displayed.size():fps_step=maxf(fps_step,last[i].distance_to(enemy.art.displayed[i]))
   last=enemy.art.displayed.duplicate()
  check(enemy.art.bridge_left==0,"bridge completes at %d FPS"%fps)
  check(fps_step<31,"bridge motion remains bounded at %d FPS"%fps)
 var support_stable=true
 for x in range(0,enemy.art.NX+1):
  var i=enemy.art.NY*(enemy.art.NX+1)+x
  support_stable=support_stable and absf(enemy.art.displayed[i].y)<.001
 check(support_stable,"grounded pose bridge keeps the support row planted")
 game.audio.stop_all();game.queue_free();await process_frame
 print("ENEMY_POSE_BRIDGE max_step=",max_step," failures=",failed);quit(failed)
