extends SceneTree
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.start_new(false)
 for stage in [2,3]:
  game.load_stage(stage,1);game.player.position=Vector2(5200,300);game.player.invincible=999
  for e in game.enemies:e.dead=true;e.visible=false
  game.hint_time=0
  await create_timer(.6).timeout;await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://builds/qa/crossing-%s.png"%stage)
  print("CROSSING ",stage," ripples=",game.terrain.presence.ripples.size())
 game.audio.stop_all();game.queue_free();await process_frame;quit()
