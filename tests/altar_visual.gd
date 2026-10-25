extends SceneTree
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.load_stage(3,0)
 game.set_process(false)
 for enemy in game.enemies:enemy.set_physics_process(false);enemy.hide()
 game.player.set_physics_process(false);game.player.invincible=0
 for x in [500,12500]:
  game.player.position=Vector2(x-180,425 if x==5150 else (360 if x==6330 else 450));game.player.velocity=Vector2(0,5);game.player.move_and_slide()
  game.camera.position=Vector2(x,330);game.hint_time=0
  await create_timer(.05).timeout;await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://builds/qa/altar-%d.png"%x)
 game.audio.stop_all();await create_timer(.1).timeout;game.queue_free();await process_frame;quit()
