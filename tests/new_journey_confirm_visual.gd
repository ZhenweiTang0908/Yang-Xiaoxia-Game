extends SceneTree
var game
func _initialize():call_deferred("run")
func run():
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.developer_mode=false
	game.progress.level=2;game.progress.checkpoint=1;game.progress.entry_section=2;game.progress.bow=true;game.progress.gourd=true
	game.progress.story_seen=true;game.progress.upgrades=["blade","spirit","brother"];game.progress.relics=["moon_1_roof","moon_1_seal","moon_2_roof"]
	game.progress.records={"1":{"standard":{"completions":2,"best_seconds":92.0,"best_kills":24,"best_clears":4}}};game.progress.journey_mode="relaxed"
	game.elapsed=754;game.kills=38;game.state="new_confirm"
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/private/tmp/yang-new-journey-confirm.png")
	game.audio.stop_all();game.queue_free();await process_frame;quit()
