extends SceneTree
var game
var failures=[]
var checks=0

func _initialize():call_deferred("run")
func verify(condition,label):
	checks+=1
	if condition:print("PASS ",label)
	else:failures.append(label);push_error("FAIL "+label)
func redraw():
	game.hud.canvas.queue_redraw();await process_frame
func actions():return game.hud.buttons.map(func(item):return item.action)
func run():
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.start_new(false)
	await process_frame
	game.elapsed=75.9;game.kills=6;game.progress.upgrades=["blade"]
	game.journey_clears={"1:0":true,"1:2":true,"2:0":true}
	game.capture_stage_result()
	var first=game.stage_result
	verify(is_equal_approx(first.seconds,75.9) and first.kills==6,"stage result measures the current attempt")
	verify(first.clears==2 and first.upgrades==1,"stage result counts current-stage clears and upgrades")
	verify(game.hud.format_time(65.8)=="01:05","result time uses stable minute-second formatting")

	game.load_stage(1,0);game.elapsed+=12.5;game.kills+=2;game.progress.upgrades.append("spirit")
	game.capture_stage_result();var retry=game.stage_result
	verify(is_equal_approx(retry.seconds,12.5) and retry.kills==2 and retry.upgrades==1,"retry starts a fresh attempt window")
	game.journey_clears["1:0"]=true
	verify(game.journey_clears.size()==3,"repeated section clears remain unique in journey totals")

	game.load_stage(2,0);game.elapsed+=42;game.kills+=5;game.progress.upgrades.append("brother")
	game.journey_clears["2:1"]=true;game.finish_level();await redraw()
	verify(game.state=="stage_clear" and game.stage_result.level==2,"stage completion freezes its result snapshot")
	verify(game.stage_record(2,"standard").completions==1,"stage completion persists its journey record")
	var stage_actions=actions()
	verify(stage_actions.has("next") and stage_actions.has("settings") and stage_actions.has("title"),"stage result preserves navigation actions")

	game.load_stage(3,0);game.elapsed+=88;game.kills+=7;game.journey_clears["3:0"]=true;game.finish_level();await redraw()
	verify(game.state=="win","final stage opens the journey result")
	var win_actions=actions()
	verify(win_actions.has("new") and win_actions.has("settings") and win_actions.has("title"),"journey result preserves restart and navigation actions")
	game.audio.stop_all();game.queue_free();await process_frame;await process_frame;await create_timer(.2).timeout;OS.delay_msec(100)
	print("STAGE_RESULTS_RESULT checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
