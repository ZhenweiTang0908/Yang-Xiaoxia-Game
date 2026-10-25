extends SceneTree
var game
func _initialize():call_deferred("run")
func run():
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.load_stage(3,2);await process_frame
	var boss=game.boss;boss.active_battle=true;boss.position=Vector2(14750,450);game.player.position=Vector2(14520,450);game.camera.position=Vector2(14750,270)
	boss.begin_phase_shift(2)
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/private/tmp/yang-boss-phase-shift.png")
	game.audio.stop_all();game.queue_free();await process_frame;quit()
