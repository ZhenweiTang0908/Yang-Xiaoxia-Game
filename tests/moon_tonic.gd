extends SceneTree
var failures=[]
var checks=0
var game
const STORE=preload("res://scripts/core/save_store.gd")
const PATH="user://moon_tonic_test.json"

func _initialize():call_deferred("run")
func verify(condition,label):
	checks+=1
	if condition:print("PASS ",label)
	else:failures.append(label);push_error("FAIL "+label)
func cleanup():
	for suffix in ["",STORE.TEMP_SUFFIX,STORE.BACKUP_SUFFIX]:
		var path=PATH+suffix
		if FileAccess.file_exists(path):DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
func key_r():
	var event=InputEventKey.new();event.pressed=true;event.physical_keycode=KEY_R;game._input(event)
func pad_up():
	var event=InputEventJoypadButton.new();event.pressed=true;event.button_index=JOY_BUTTON_DPAD_UP;game.gamepad.handle(event)
func touch_item():
	var item=game.hud.touch_layout().filter(func(entry):return entry.action=="item")[0]
	var event=InputEventScreenTouch.new();event.index=7;event.pressed=true;event.position=item.rect.get_center();game._input(event)
func run():
	cleanup();var old=STORE.defaults();old.erase("tonic");STORE.write_save(old,PATH)
	verify(STORE.read_save(PATH).tonic==2,"legacy saves receive two moon tonic charges")
	var hostile=STORE.defaults();hostile.tonic=9;STORE.write_save(hostile,PATH);verify(STORE.read_save(PATH).tonic==2,"excess tonic count is clamped")
	hostile.tonic=-5;STORE.write_save(hostile,PATH);verify(STORE.read_save(PATH).tonic==0,"negative tonic count is clamped")
	cleanup()

	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.start_new(false);await process_frame
	verify(game.progress.tonic==2,"new journey starts with two moon tonic charges")
	var p=game.player;p.health=100
	verify(not game.use_tonic() and game.progress.tonic==2 and "生命已满" in game.hint,"full health refuses tonic without consuming it")
	p.health=70;verify(game.use_tonic() and p.health==100 and game.progress.tonic==1,"tonic heals to the cap without an extra recovery banner")
	p.health=40;verify(game.use_tonic() and p.health==75 and game.progress.tonic==0,"second tonic heals thirty-five and consumes the final charge")
	verify(not game.use_tonic() and p.health==75 and "已用尽" in game.hint,"empty tonic inventory refuses use without changing health")

	game.progress.tonic=2;p.health=50;key_r()
	verify(p.health==85 and game.progress.tonic==1,"keyboard R uses a real tonic")
	game.progress.tonic=2;p.health=50;pad_up()
	verify(p.health==85 and game.progress.tonic==1,"controller up uses a real tonic")
	game.progress.tonic=2;p.health=50;touch_item()
	verify(p.health==85 and game.progress.tonic==1,"touch tonic button uses a real tonic")
	game.state="paused";game.progress.tonic=2;p.health=50
	verify(not game.use_tonic() and p.health==50 and game.progress.tonic==2,"paused play cannot consume tonic")

	game.state="playing";game.progress.tonic=0;game.player.position.x=game.level.checkpoints[1]+1;game._physics_process(.016)
	verify(game.state=="upgrade" and game.progress.tonic==2,"reaching a lantern replenishes tonic before martial choice")
	game.progress.tonic=1;game.progress.pending_upgrade={};game.retry();await process_frame
	verify(game.progress.tonic==1,"checkpoint retry preserves remaining tonic")
	game.progress.tonic=0;game.state="stage_clear";game.next_level();await process_frame
	verify(game.progress.level==2 and game.progress.tonic==2,"entering the next stage replenishes tonic")
	verify(STORE.write_save(game.progress,PATH) and STORE.read_save(PATH).tonic==2,"tonic count survives a save round trip")
	cleanup();game.audio.stop_all();game.queue_free();await process_frame;await process_frame;await create_timer(.2).timeout;OS.delay_msec(100)
	print("MOON_TONIC_RESULT checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
