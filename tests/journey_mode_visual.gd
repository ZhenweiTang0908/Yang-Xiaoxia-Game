extends SceneTree
var game
func _initialize():call_deferred("run")
func capture(path):
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
func run():
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true
	game.progress.journey_mode="relaxed";game.state="settings"
	await capture("/private/tmp/yang-journey-mode-settings.png")
	game.start_new(false);await process_frame;game.state="paused"
	await capture("/private/tmp/yang-journey-mode-pause.png")
	game.audio.stop_all();game.queue_free();await process_frame;quit()
