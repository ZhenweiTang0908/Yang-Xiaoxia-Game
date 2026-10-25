extends SceneTree
var game

func _initialize():call_deferred("run")
func feature_node():
	for child in game.terrain.get_children():
		if child.get_script() and child.get_script().resource_path.ends_with("room_features.gd"):return child
	return null
func capture(name):
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/private/tmp/yang-level-"+name+".png")
func run():
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true
	game.load_stage(2,0)
	var features=feature_node();var gust=features.items.filter(func(item):return item.kind=="gust")[0]
	game.player.position=Vector2(gust.x+gust.w*.5,450);game.camera.position=Vector2(game.player.position.x+170,270)
	for enemy in game.enemies:enemy.set_physics_process(false)
	features.set_physics_process(false);features.clock=1.4;await capture("mist-current")
	game.load_stage(3,0)
	features=feature_node();var ritual=features.items.filter(func(item):return item.kind=="ritual")[1]
	game.player.position=Vector2(ritual.x-150,450);game.camera.position=Vector2(ritual.x,270)
	for enemy in game.enemies:enemy.set_physics_process(false)
	features.set_physics_process(false);features.clock=ritual.period-ritual.get("phase",0.0)-.55;await capture("ritual-warning")
	features.clock=ritual.period-ritual.get("phase",0.0)-.12;await capture("ritual-active")
	game.audio.stop_all();await create_timer(.2).timeout
	game.queue_free();await process_frame;await process_frame;quit()
