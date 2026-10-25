extends SceneTree
var game
func _initialize():call_deferred("run")
func run():
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.load_stage(1,2)
 game.player.position=Vector2(14710,450);game.player.invincible=999
 for enemy in game.enemies:enemy.set_physics_process(false)
 var b=game.boss;b.active_battle=true;b.position=Vector2(14850,450)
 game.camera.position=Vector2(14750,270)
 for move in [0,1,2]:
  game.combat.clear();b.start_move(move);b.release_move()
  # The physics test proves behavior; this capture isolates the active visual.
  if move==0:
   for h in game.combat.hazards:h.delay=0
  await create_timer(.08).timeout;await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://builds/qa/lantern-move-%s.png"%move)
 game.audio.stop_all();quit()
