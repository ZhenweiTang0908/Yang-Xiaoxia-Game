extends SceneTree
var failures=[]
var checks=0
var game
const STORE=preload("res://scripts/core/save_store.gd")
const PATH="user://journey_mode_test.json"

func _initialize():call_deferred("run")
func verify(condition,label):
	checks+=1
	if condition:print("PASS ",label)
	else:failures.append(label);push_error("FAIL "+label)
func actions():return game.hud.buttons.map(func(button):return button.action)
func redraw():
	game.hud.canvas.queue_redraw();await process_frame;await process_frame
func cleanup():
	for suffix in ["",STORE.TEMP_SUFFIX,STORE.BACKUP_SUFFIX]:
		var path=PATH+suffix
		if FileAccess.file_exists(path):DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
func run():
	cleanup()
	var legacy=STORE.defaults();legacy.erase("journey_mode");STORE.write_save(legacy,PATH)
	verify(STORE.defaults().journey_mode=="standard" and STORE.read_save(PATH).journey_mode=="standard","new and legacy saves default to standard journey")
	cleanup()
	var invalid=STORE.defaults();invalid.journey_mode="unknown";STORE.write_save(invalid,PATH)
	verify(STORE.read_save(PATH).journey_mode=="standard","unknown journey mode falls back safely")
	cleanup()
	var relaxed=STORE.defaults();relaxed.journey_mode="relaxed";STORE.write_save(relaxed,PATH)
	verify(STORE.read_save(PATH).journey_mode=="relaxed","relaxed journey survives a save round trip")
	cleanup()

	game=load("res://scenes/main.tscn").instantiate();root.add_child(game)
	game.qa_mode=true;game.developer_mode=false;game.start_new(false);await process_frame
	game.state="settings";await redraw()
	verify("journey_mode" in actions(),"release settings expose the journey strength control")
	game.hud.action("journey_mode")
	verify(game.relaxed_journey(),"journey strength toggles immediately")
	game.state="playing";var p=game.player;p.health=100;p.invincible=0;p.take_damage(20,0)
	verify(is_equal_approx(p.health,86),"relaxed journey applies seventy percent real incoming damage")
	p.health=100;p.invincible=0;game.progress.journey_mode="standard";p.take_damage(20,0)
	verify(is_equal_approx(p.health,80),"standard journey preserves original incoming damage")
	p.health=100;p.invincible=0;game.progress.journey_mode="relaxed";game.fall_recover()
	verify(is_equal_approx(p.health,87.4),"relaxed journey also covers fall recovery damage")
	game.start_new(false);await process_frame
	verify(game.relaxed_journey(),"new journey preserves the accessibility preference")
	game.state="paused";await redraw()
	verify(game.relaxed_journey() and "settings" in actions(),"paused journey keeps the active preference and settings route")
	game.audio.stop_all();game.queue_free();await process_frame;await process_frame;await create_timer(.2).timeout;OS.delay_msec(100)
	print("JOURNEY_MODE_RESULT checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
