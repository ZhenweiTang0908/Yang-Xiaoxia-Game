extends SceneTree
var game

func _initialize():call_deferred("run")
func capture(path):
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
func run():
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.start_new(false)
	for i in 4:await process_frame
	game.progress.upgrades=["blade","spirit","blade","brother"]
	game.stage_result={"level":1,"seconds":421.0,"kills":22,"clears":3,"upgrades":2}
	game.state="stage_clear";await capture("/private/tmp/yang-stage-result.png")
	game.elapsed=1184;game.kills=69
	for level_number in 3:
		for section in 3:game.journey_clears[str(level_number+1)+":"+str(section)]=true
	game.stage_result={"level":3,"seconds":388.0,"kills":23,"clears":3,"upgrades":2}
	game.state="win";await capture("/private/tmp/yang-journey-result.png")
	game.audio.stop_all();game.queue_free();await process_frame;await process_frame;quit()
