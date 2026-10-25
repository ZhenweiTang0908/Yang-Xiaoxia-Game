extends SceneTree
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.start_new(false)
 await create_timer(.15).timeout
 game.combat.set_physics_process(false);game.combat.clear()
 var origin=game.player.position+Vector2(150,-55)
 for i in 5:
  game.combat.fire(origin+Vector2(i*34,0),Vector2.RIGHT*100,0,"enemy","ghost_orb",{"life":3.0})
 for i in 3:
  game.combat.fire(origin+Vector2(i*70,-55),Vector2.RIGHT*100,0,"enemy","ghost_orb",{"life":3.0,"homing":true})
 await process_frame;await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/qa/ghost-orb-variants.png")
 game.queue_free();await process_frame;quit()
