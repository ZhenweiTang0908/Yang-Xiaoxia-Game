extends SceneTree
var game
func _initialize():call_deferred("run")
func run():
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.developer_mode=false
	game.start_new(false);await process_frame
	game.player.health=1;game.player.invincible=0;game.player.take_damage(100,0,"spirit_lightning")
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/private/tmp/yang-death-guide.png")
	game.audio.stop_all();game.queue_free();await process_frame;quit()
