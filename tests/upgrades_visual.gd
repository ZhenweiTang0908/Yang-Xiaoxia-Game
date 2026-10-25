extends SceneTree
var game

func _initialize():call_deferred("run")
func run():
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.start_new(false)
	for i in 4:await process_frame
	game.player.position.x=game.level.checkpoints[1]+5
	for i in 3:await physics_frame
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/private/tmp/yang-upgrades.png")
	game.audio.stop_all();game.queue_free();await process_frame;await process_frame;quit()
