extends SceneTree
var failures=[]
var checks=0
var game

func _initialize():call_deferred("run")
func verify(condition,label):
	checks+=1
	if condition:print("PASS ",label)
	else:failures.append(label);push_error("FAIL "+label)
func redraw():
	game.hud.canvas.queue_redraw();await process_frame;await process_frame
func actions():return game.hud.buttons.map(func(button):return button.action)
func key(code):
	var event=InputEventKey.new();event.pressed=true;event.physical_keycode=code;game._input(event)
func pad(button):
	game.gamepad.glyphs="switch";var event=InputEventJoypadButton.new();event.pressed=true;event.button_index=button;game.gamepad.handle(event)
func seed_progress():
	game.progress.level=2;game.progress.checkpoint=1;game.progress.entry_section=2
	game.progress.bow=true;game.progress.gourd=true;game.progress.story_seen=true;game.progress.completed=false
	game.progress.upgrades=["blade","spirit"];game.progress.pending_upgrade={"level":2,"checkpoint":1}
	game.progress.relics=["moon_1_roof","moon_2_seal"]
	game.progress.records={"1":{"standard":{"completions":2,"best_seconds":80.0,"best_kills":20,"best_clears":4}}}
	game.progress.music=.4;game.progress.sfx=.5;game.progress.ambience=.6;game.progress.muted=true;game.progress.screen_shake=false;game.progress.journey_mode="relaxed"
	game.elapsed=125;game.kills=17;game.journey_clears={"1:0":true}
func run():
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.developer_mode=false
	game.progress=game.SAVE.defaults();game.progress.relics=["moon_1_roof"];game.progress.records={"1":{"standard":{"completions":1}}}
	verify(not game.has_journey_progress(),"permanent collections alone do not make a journey active")
	game.state="title";await redraw();var new_button=game.hud.buttons.filter(func(button):return button.action=="new")[0]
	game.hud.handle_click(new_button.rect.get_center());await process_frame
	verify(game.state=="playing" and game.progress.level==1,"a pristine save starts immediately without a redundant prompt")
	game.progress=game.SAVE.defaults();game.elapsed=8;game.state="title";game.hud.action("new")
	verify(game.state=="new_confirm","early play before the first lantern is still protected")
	game.hud.action("new_confirm_back");game.elapsed=0

	seed_progress();game.state="title";var before=game.progress.duplicate(true);game.hud.action("new")
	verify(game.state=="new_confirm" and game.progress==before,"title action opens confirmation without mutating active progress")
	await redraw();var confirm_actions=actions()
	verify(confirm_actions==["new_confirm_back","new_confirm_start"],"confirmation exposes only safe return and explicit restart, with safe controller focus first")
	var frozen=game.elapsed;game._process(.5)
	verify(is_equal_approx(game.elapsed,frozen) and not game.world.visible,"confirmation freezes time and hides the playable world")
	key(KEY_ESCAPE)
	verify(game.state=="title" and game.progress==before,"Escape returns to the title without changing progress")

	key(KEY_ENTER);verify(game.state=="new_confirm","Enter from the title follows the same confirmation path")
	key(KEY_ENTER);await process_frame
	verify(game.state=="playing" and game.progress.level==1 and game.progress.checkpoint==0 and game.progress.entry_section==0,"second Enter confirms and restarts at the first lantern")
	# The boss rush starts equipped, back at the first boss with no clears or upgrades.
	verify(game.boss_rush and game.progress.rush_stage==1 and game.progress.rush_clears.is_empty() and game.progress.upgrades.is_empty() and game.progress.bow and game.progress.gourd and not game.progress.story_seen and not game.progress.completed,"restart begins the boss rush from the first boss")
	verify(game.progress.upgrades.is_empty() and game.progress.pending_upgrade.is_empty() and game.elapsed<.1 and game.kills==0 and game.journey_clears.is_empty(),"restart clears martial and in-memory attempt progress")
	verify(game.progress.relics==before.relics and game.progress.records==before.records,"restart preserves relics and journey records")
	verify(game.progress.journey_mode=="relaxed" and is_equal_approx(game.progress.music,.4) and game.progress.muted and not game.progress.screen_shake,"restart preserves difficulty, audio and comfort settings")

	seed_progress();game.state="title";game.hud.action("new");await redraw();pad(JOY_BUTTON_B)
	verify(game.state=="title" and game.progress.level==2,"controller confirm defaults to the safe keep-current-journey choice")
	game.hud.action("new");pad(JOY_BUTTON_A)
	verify(game.state=="title" and game.progress.level==2,"controller back also cancels without mutation")

	game.state="win";game.hud.action("new");await process_frame
	verify(game.state=="playing" and game.progress.level==1,"explicit final-result restart remains direct")
	game.audio.stop_all();game.queue_free();await process_frame;await process_frame;await create_timer(.2).timeout;OS.delay_msec(100)
	print("NEW_JOURNEY_CONFIRM_RESULT checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
