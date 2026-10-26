extends SceneTree
var failures=[]
var checks=0
func _initialize():call_deferred("run")
func verify(ok,label):
	checks+=1
	if not ok:failures.append(label);push_error(label)
func run():
	var game=load("res://scenes/main.tscn").instantiate();root.add_child(game)
	game.qa_mode=true;game.progress=game.SAVE.defaults();game.start_new(false)
	await process_frame;await process_frame
	var hero=game.player
	verify(hero.z_index==4096,"hero starts at the top world draw layer")
	var rider=Node2D.new();root.add_child(rider);hero.attach_to(rider)
	verify(hero.z_index==4096,"mounting preserves the top world draw layer")
	hero.detach_from(hero.position)
	verify(hero.z_index==4096,"dismounting preserves the top world draw layer")
	rider.queue_free();game.audio.stop_all();game.queue_free();await process_frame;await process_frame
	print("PLAYER_TOP_LAYER_RESULT checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
