extends SceneTree
var game
func _initialize():call_deferred("run")
func capture(path):
	game.hud.canvas.queue_redraw()
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
func run():
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.developer_mode=false
	# Let deferred startup finish before selecting the page to capture.
	await process_frame;await process_frame
	game.progress.records={"1":{"standard":{"completions":3,"best_seconds":92.4,"best_kills":24,"best_clears":4}},"2":{"standard":{"completions":1,"best_seconds":151.0,"best_kills":19,"best_clears":2}}}
	game.progress.relics=["moon_1_roof","moon_1_seal","moon_2_roof"]
	game.hud.journey_records_mode="standard";game.state="journey_records"
	await capture("/private/tmp/yang-journey-records.png")
	game.state="title";await capture("/private/tmp/yang-journey-records-title.png")
	game.start_new(false);await process_frame;game.stage_result={"level":1,"seconds":92.4,"kills":24,"clears":4,"upgrades":2};game.state="stage_clear"
	await capture("/private/tmp/yang-journey-records-result.png")
	game.audio.stop_all();game.queue_free();await process_frame;quit()
