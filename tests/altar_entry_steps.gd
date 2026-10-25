extends SceneTree
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.start_new(false);game.load_stage(3,2)
 for enemy in game.enemies:enemy.dead=true;enemy.hide();enemy.set_physics_process(false)
 var p=game.player;p.position=Vector2(12120,450);p.invincible=999
 for i in 240:
  if p.position.x<12420:
   Input.action_press("right")
   if p.is_on_floor():p.enqueue("jump")
  else:Input.action_release("right")
  await physics_frame
 Input.action_release("right")
 var ok=p.position.x>12400 and p.is_on_floor() and absf(p.position.y-365)<2
 print("ALTAR_ENTRY_STEPS ","PASS" if ok else "FAIL"," position=",p.position)
 if DisplayServer.get_name()!="headless":
  game.camera.position=Vector2(12330,300);game.hint_time=0;game.subtitle_time=0
  await process_frame;await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://builds/qa/altar-entry-steps.png")
 game.progress.gourd=true;game.summon.reset(true);game.summon.request()
 for i in 85:await physics_frame
 var brother=game.summon.brother;brother.position=Vector2(12130,450);brother.velocity=Vector2.ZERO
 var warped=false
 for i in 200:
  var before=brother.position
  await physics_frame
  if brother.position.distance_to(before)>80:warped=true
 var followed=brother.position.x>12340 and brother.is_on_floor() and not warped
 print("ALLY_STAIRS natural_follow=",followed," position=",brother.position)
 ok=ok and followed
 for i in 160:
  if p.position.x>12120:Input.action_press("left")
  else:Input.action_release("left")
  await physics_frame
 Input.action_release("left")
 var returned=p.position.x<12130 and p.is_on_floor() and absf(p.position.y-450)<2
 print("ALTAR_RETURN ",returned)
 ok=ok and returned
 game.audio.stop_all();game.queue_free();await process_frame;quit(0 if ok else 1)
