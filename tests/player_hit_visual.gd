extends SceneTree
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.start_new(false)
 for e in game.enemies:e.set_physics_process(false);e.hide()
 var p=game.player;p.position=Vector2(300,450)
 for i in 5:await physics_frame
 game.fx.clear();p.invincible=0;p.health=100;p.take_damage(12,1)
 var ok=p.health==88 and game.fx.particles.is_empty() and game.fx.impacts.size()==1
 print("PLAYER_HIT health=",p.health," random_particles=",game.fx.particles.size()," contacts=",game.fx.impacts.size())
 game.set_process(false);game.camera.position=Vector2(340,380);game.camera.zoom=Vector2(2,2)
 await create_timer(.04).timeout;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/qa/player-hit.png")
 game.audio.stop_all();game.queue_free();await process_frame;await create_timer(.1).timeout;quit(0 if ok else 1)
