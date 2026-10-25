extends SceneTree
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.gamepad.reset_bindings();game.gamepad.glyphs="ps";game.hud.action("controls")
 await create_timer(.4).timeout;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/qa/animation/controller-settings.png")
 game.queue_free();await process_frame;quit()
