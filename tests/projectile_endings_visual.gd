extends SceneTree
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.start_new(false)
 await create_timer(.2).timeout
 game.combat.set_physics_process(false);game.combat.clear()
 for i in 3:
  game.combat.fire(game.player.position+Vector2(60+i*55,-55),Vector2(20,0),0,"brother",["card","flame","blade"][i],{"life":.001})
 game.combat._physics_process(.01);game.combat._physics_process(.05)
 print("ENDINGS_VISUAL ",game.combat.shot_endings.size())
 await process_frame;await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/qa/projectile-endings.png")
 game.queue_free();await process_frame;quit()
