extends SceneTree
var failures=[]
func _initialize():call_deferred("run")
func frames(count):
 for i in count:await physics_frame
 await process_frame
func check(ok,label):
 print("PASS " if ok else "FAIL ",label)
 if not ok:failures.append(label)
func run():
 root.size=Vector2i(960,540);root.content_scale_size=root.size
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.start_new(false)
 for enemy in game.enemies:enemy.set_physics_process(false);enemy.dead=true
 var p=game.player;p.position=Vector2(180,450);p.invincible=0
 p.set_physics_process(false)
 p.art.show();p.heavy_art.show()
 p.skeletal_visual._process(1.0/60)
 check(not p.art.visible and not p.heavy_art.visible,"render ownership hides legacy art without player physics")
 p.set_physics_process(true)
 await frames(8)
 var visual=p.skeletal_visual;var motion=visual.painted_motion
 check(motion.rig.parts.size()==12 and motion.rig.strip_count==0,"cached production mesh includes an independently hideable blade")
 check(motion.visible and not visual.skin.visible and not visual.heavy_skin.visible,"one human renderer while idle")
 Input.action_press("right");await frames(15);Input.action_release("right")
 check(motion.last_state=="run" and motion.rig.sampled_pose.size()==11,"real movement drives continuous rig")
 p.enqueue("jump");await frames(8)
 check(not p.is_on_floor() and motion.rig.planted==[null,null],"jump releases both planted feet")
 await frames(60)
 p.set_physics_process(false);p.velocity=Vector2.ZERO;p.land_anim=0;p.hurt_anim=0
 for state in ["slash1","slash2","slash3","bow","charge","roll","dash","hurt","idle"]:
  p.attack_elapsed=-1;p.bow_anim=0;p.charge=0;p.dash_time=0;p.hurt_anim=0
  if state.begins_with("slash"):p.combo=int(state.right(1));p.attack_elapsed=.15
  if state=="bow":p.bow_anim=.25
  if state=="charge":p.charge=.5
  if state=="roll":p.dash_time=.15;p.sprinting=false
  if state=="dash":p.dash_time=.15;p.sprinting=true
  if state=="hurt":p.hurt_anim=.15
  await frames(3)
  var supported=motion.supports(state)
  check(motion.visible==supported and (visual.skin.visible or visual.heavy_skin.visible)!=supported,"exclusive renderer for "+state)
 p.sheep_time=10;p.form_visual=true;await frames(3)
 check(not visual.visible,"human hidden in sheep form")
 p.sheep_time=0;p.form_visual=false;await frames(3)
 check(visual.visible and motion.visible,"human restored after sheep form")
 var pose=motion.rig.sampled_pose.duplicate();game.state="paused";await frames(5)
 check(pose==motion.rig.sampled_pose,"pause freezes rig")
 game.state="playing";game.camera.position=Vector2(p.position.x,270);game.hint_time=0
 if DisplayServer.get_name()!="headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://builds/qa/painted-in-game.png")
 game.audio.stop_all();await create_timer(.1).timeout;game.queue_free();await process_frame
 print("PAINTED_GAME failures=",failures)
 quit(0 if failures.is_empty() else 1)
