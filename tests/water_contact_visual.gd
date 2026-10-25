extends SceneTree
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.start_new(false)
 for enemy in game.enemies:enemy.set_physics_process(false);enemy.hide()
 game.player.position=Vector2(2200,450);game.player.velocity=Vector2.ZERO;game.player.invincible=0
 await create_timer(.1).timeout
 game.set_process(false);game.player.set_physics_process(false);game.camera.position=Vector2(2200,400);game.camera.zoom=Vector2(2,2);game.hint_time=0
 var effect=game.terrain.presence
 effect.step(game.player.position,true)
 for i in 3:
  await create_timer(.1).timeout;await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://builds/qa/water-contact-%d.png"%i)
 game.audio.stop_all();await create_timer(.1).timeout;game.queue_free();await process_frame;quit()
