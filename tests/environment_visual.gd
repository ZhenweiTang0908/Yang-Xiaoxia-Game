extends SceneTree
var game
func _initialize():call_deferred("run")
func capture(name):
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("/private/tmp/yang-scene-"+name+".png")
func run():
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true
 for n in [1,2,3]:
  game.jump_to_stage(n,0)
  for e in game.enemies:e.set_physics_process(false)
  await create_timer(1.1).timeout
  game.player.invincible=0;game.player.art.tint.a=1
  await capture(str(n))
 game.jump_to_stage(3,6);game.player.position=Vector2(30600,450);game.player.invincible=100
 game.boss.position=Vector2(30800,450);game.boss.active_battle=true;game.boss.facing=-1
 for e in game.enemies:e.set_physics_process(false)
 game.camera.position=Vector2(30750,270);game.player.invincible=0;game.player.art.tint.a=1
 game.boss.art.frame=15;game.boss.art.facing=1
 game.boss.start_move(6);game.boss.windup=0;game.boss.release_move()
 await create_timer(.15).timeout
 await capture("fire")
 game.audio.stop_all();game.queue_free();await process_frame;await create_timer(.2).timeout;quit()
