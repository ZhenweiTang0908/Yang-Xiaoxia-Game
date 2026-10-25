extends SceneTree
var game

func _initialize():call_deferred("run")
func capture(path):
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
func run():
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.start_new(false)
	for i in 4:await process_frame
	game.progress.relics=["moon_1_roof","moon_1_seal","moon_2_seal"]
	game.state="paused";await capture("/private/tmp/yang-pause-journal-entry.png")
	game.hud.action("relic_journal");await capture("/private/tmp/yang-relic-journal.png")
	game.audio.stop_all();game.queue_free();await process_frame;await process_frame;quit()
