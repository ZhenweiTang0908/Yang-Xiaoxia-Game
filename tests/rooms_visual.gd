extends SceneTree
var game
func _initialize():call_deferred("run")
func run():
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.start_new(false)
 for room in 4:
  game.player.position=Vector2([1250,5300,9950,14700][room],300 if room<3 else 450);game.player.invincible=999
  for e in game.enemies:e.set_physics_process(false)
  game.camera.position=Vector2(game.player.position.x+150,270)
  await create_timer(.25).timeout;await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://builds/qa/room-%s.png"%room)
 game.audio.stop_all();quit()
