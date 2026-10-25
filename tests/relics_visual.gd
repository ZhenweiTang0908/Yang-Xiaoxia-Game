extends SceneTree
var game

func _initialize():call_deferred("run")
func capture(path):
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
func run():
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.start_new(false)
	for i in 4:await process_frame
	var relic=game.pickups.filter(func(item):return item.kind=="relic")[0]
	game.player.position=Vector2(relic.x-70,relic.y+20);game.camera.position=Vector2(relic.x,270)
	for enemy in game.enemies:enemy.set_physics_process(false)
	await capture("/private/tmp/yang-relic-world.png")
	game.player.position=Vector2(relic.x,relic.y+20);game._physics_process(1.0/60.0)
	await capture("/private/tmp/yang-relic-collected.png")
	game.audio.stop_all();game.queue_free();await process_frame;await process_frame;quit()
