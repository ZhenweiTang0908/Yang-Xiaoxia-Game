extends SceneTree
var failures=[]
var checks=0
var game
const STORE=preload("res://scripts/core/save_store.gd")
const PATH="user://journey_records_test.json"

func _initialize():call_deferred("run")
func verify(condition,label):
	checks+=1
	if condition:print("PASS ",label)
	else:failures.append(label);push_error("FAIL "+label)
func cleanup():
	for suffix in ["",STORE.TEMP_SUFFIX,STORE.BACKUP_SUFFIX]:
		var path=PATH+suffix
		if FileAccess.file_exists(path):DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
func redraw():game.hud.canvas.queue_redraw();await process_frame;await process_frame
func actions():return game.hud.buttons.map(func(button):return button.action)
func key_escape():
	var event=InputEventKey.new();event.pressed=true;event.physical_keycode=KEY_ESCAPE;game._input(event)
func gamepad_back():
	game.gamepad.glyphs="switch";var event=InputEventJoypadButton.new();event.pressed=true;event.button_index=JOY_BUTTON_A;game.gamepad.handle(event)
func run():
	cleanup();var legacy=STORE.defaults();legacy.erase("records");STORE.write_save(legacy,PATH)
	verify(STORE.read_save(PATH).records.is_empty(),"legacy save starts with empty journey records")
	cleanup();var hostile=STORE.defaults();hostile.records={"1":{"standard":{"completions":-8,"best_seconds":-5,"best_kills":9000,"best_clears":40},"cheat":{"completions":2}},"9":{"standard":{"completions":2}}};STORE.write_save(hostile,PATH)
	verify(STORE.read_save(PATH).records.is_empty(),"invalid empty records and unknown stage or mode are discarded")
	hostile.records["1"].standard.completions=100000;STORE.write_save(hostile,PATH);var bounded=STORE.read_save(PATH).records["1"].standard
	verify(bounded.completions==9999 and bounded.best_seconds==0 and bounded.best_kills==999 and bounded.best_clears==4,"record values are clamped to safe bounds")
	cleanup()

	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.developer_mode=false;game.start_new(false);await process_frame
	var first={"level":1,"seconds":95.5,"kills":18,"clears":2};verify(game.update_stage_record(first),"first clear creates a standard record")
	var record=game.stage_record(1,"standard")
	verify(record.completions==1 and is_equal_approx(record.best_seconds,95.5) and record.best_kills==18 and record.best_clears==2,"first clear stores all record metrics")
	game.update_stage_record({"level":1,"seconds":120.0,"kills":23,"clears":4});record=game.stage_record(1,"standard")
	verify(record.completions==2 and is_equal_approx(record.best_seconds,95.5) and record.best_kills==23 and record.best_clears==4,"later clears merge independent best values")
	game.progress.journey_mode="relaxed";game.update_stage_record({"level":1,"seconds":70.0,"kills":10,"clears":1})
	verify(game.stage_record(1,"relaxed").completions==1 and game.stage_record(1,"standard").completions==2,"standard and relaxed records remain separate")
	game.progress.relics=["moon_1_roof","moon_1_seal"];game.start_new(false);await process_frame
	verify(game.stage_record(1,"standard").completions==2 and game.stage_relic_count(1)==2,"new journey preserves records and per-stage relic progress")
	verify(STORE.write_save(game.progress,PATH) and STORE.read_save(PATH).records["1"].standard.completions==2,"journey records survive a save round trip")

	game.state="title";await redraw();verify("journey_records" in actions(),"release title exposes the journey book")
	game.hud.action("journey_records");var elapsed=game.elapsed;await redraw()
	verify(game.state=="journey_records" and game.hud.journey_records_return=="title" and game.hud.journey_records_mode=="relaxed","book opens on the active journey strength and remembers its source")
	var rows=game.hud.journey_record_rows()
	verify(rows.size()==4 and rows[0].record.completions==1 and rows[0].title=="守灯石庭" and rows[3].boss=="断誓枪骑","book rows list the four boss fights with their records")
	game.hud.action("records_standard");verify(game.hud.journey_record_rows()[0].record.completions==2,"book switches between strength-specific records")
	for i in 15:await process_frame
	verify(is_equal_approx(game.elapsed,elapsed),"journey book keeps gameplay time frozen")
	key_escape();verify(game.state=="title","keyboard escape returns to the opening source")
	game.state="stage_clear";await redraw();verify("journey_records" in actions(),"stage result exposes the journey book")
	game.hud.action("journey_records");gamepad_back();verify(game.state=="stage_clear","controller back returns to the stage result")
	cleanup();game.audio.stop_all();game.queue_free();await process_frame;await process_frame;await create_timer(.2).timeout;OS.delay_msec(100)
	print("JOURNEY_RECORDS_RESULT checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
