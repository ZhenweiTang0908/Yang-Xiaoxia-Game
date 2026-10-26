extends SceneTree
var failures=[]
var checks=0
func _initialize():call_deferred("run")
func verify(ok,label):
	checks+=1
	if not ok:failures.append(label);push_error(label)
func run():
	var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true
	await process_frame;await process_frame
	game.start_new(false);await process_frame
	game.process_mode=Node.PROCESS_MODE_DISABLED
	game.state="playing";game.hitstop=0
	game._process(.1)
	var playing_time=game.ambience_clock
	game.stage_banner=playing_time
	verify(playing_time>0,"environment animation advances during gameplay")
	game.state="paused";game._process(.2)
	verify(is_equal_approx(game.ambience_clock,playing_time),"environment animation freezes in pause")
	verify(is_equal_approx(game.ambience_clock-game.stage_banner,0),"stage banner keeps its remaining time during pause")
	game.hud.resource_feedback=1.0;game.hud._process(.2)
	verify(is_equal_approx(game.hud.resource_feedback,1.0),"resource feedback freezes in pause")
	game.state="settings";game._process(.2)
	verify(is_equal_approx(game.ambience_clock,playing_time),"environment animation freezes in menus")
	game.state="playing";game.hitstop=.1;game._process(.2)
	verify(is_equal_approx(game.ambience_clock,playing_time),"environment animation freezes during hitstop")
	game.hud._process(.2)
	verify(is_equal_approx(game.hud.resource_feedback,1.0),"resource feedback freezes during hitstop")
	game.hitstop=0;game._process(.1)
	game.hud._process(.2)
	verify(game.ambience_clock>playing_time,"environment animation resumes after combat continues")
	verify(game.hud.resource_feedback<1.0,"resource feedback fades when combat resumes")
	game.queue_free();await process_frame
	print("AMBIENCE_PAUSE_RESULT checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
