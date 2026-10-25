extends SceneTree
var failures=[]
var checks=0
var game

func _initialize():call_deferred("run")
func verify(condition,label):
	checks+=1
	if condition:print("PASS ",label)
	else:failures.append(label);push_error("FAIL "+label)
func actions():return game.hud.buttons.map(func(button):return button.action)
func redraw():
	game.hud.canvas.queue_redraw()
	await process_frame
	await process_frame
func run():
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.progress=game.SAVE.defaults();game.tuning.reset()
	game.developer_mode=false;game.state="title";await redraw()
	verify("debug" in actions() and is_instance_valid(game.debug_panel),"release title exposes the parameter panel")
	game.hud.action("debug")
	verify(game.state=="debug" and game.debug_panel.root.visible,"release title opens parameter panel")
	var key=InputEventKey.new();key.physical_keycode=KEY_F2;key.pressed=true;game._input(key)
	verify(game.state=="title" and not game.debug_panel.root.visible,"F2 closes panel back to title")
	verify("stage_select" in actions(),"release title exposes stage select")
	verify(not "animation_lab" in actions(),"release title hides animation lab")
	game.developer_mode=true;await redraw()
	verify("debug" in actions() and "stage_select" in actions() and "animation_lab" in actions(),"developer title exposes tools")
	game.start_new(false);await process_frame;game.developer_mode=false;await redraw()
	verify("debug" in actions() and "stage_select" in actions(),"release HUD exposes parameters and stage select")
	verify("pause" in actions() and "settings" in actions(),"release HUD keeps player controls")
	game._input(key)
	verify(game.state=="debug" and not game.active(),"F2 pauses release combat and opens panel")
	var original=game.tuning.get_value("demon_damage")
	game.debug_panel.spins.demon_damage.get_line_edit().text=str(original+1);game.debug_panel.apply_values()
	verify(game.tuning.get_value("demon_damage")==original+1,"panel edits apply to actual tuning")
	game.debug_panel.defaults();game.debug_panel.apply_values()
	verify(game.tuning.get_value("demon_damage")==game.tuning.SCHEMA.demon_damage[1],"panel defaults restore actual tuning")
	key.physical_keycode=KEY_ESCAPE;game._input(key)
	verify(game.state=="playing" and not game.debug_panel.root.visible,"Esc returns from parameters to combat")
	game.state="paused";await redraw()
	verify("stage_select" in actions() and "resume" in actions() and "title" in actions(),"release pause menu keeps stage select")
	game.debug_panel.toggle();game.debug_panel.close()
	verify(game.state=="paused","closing parameters preserves prior pause state")
	game.state="playing"
	var original_shake=game.progress.screen_shake;game.hud.action("screen_shake")
	verify(game.progress.screen_shake!=original_shake,"screen shake setting toggles")
	game.shake=3;game.progress.screen_shake=false;game._process(.016)
	verify(game.camera.offset==Vector2.ZERO,"disabled screen shake keeps camera steady")
	game.audio.stop_all();await create_timer(.2).timeout
	game.queue_free();await process_frame;await process_frame
	OS.delay_msec(100)
	print("RELEASE_UI_RESULT checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
