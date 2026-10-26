extends SceneTree
var failures=[]
var checks=0
var game
func _initialize():call_deferred("run")
func verify(ok,label):
	checks+=1
	if not ok:failures.append(label);push_error(label)
func key(code,echo=false):
	var event=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=true;event.echo=echo;game._input(event)
func run():
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game)
	await process_frame;await process_frame
	game.qa_mode=true;game.progress=game.SAVE.defaults();game.state="title";game.hud.canvas.queue_redraw()
	await process_frame;await process_frame
	var stage_index=game.hud.buttons.find_custom(func(entry):return entry.action=="stage_select")
	key(KEY_DOWN)
	verify(game.hud.pad_focus==stage_index,"initial keyboard direction moves focus immediately")
	key(KEY_DOWN,true)
	verify(game.hud.pad_focus==stage_index,"keyboard repeat waits through the initial navigation delay")
	game._process(.37);key(KEY_DOWN,true)
	verify(game.hud.pad_focus!=stage_index,"held direction repeats after the initial delay")
	game.audio.stop_all();game.queue_free();await process_frame;await process_frame
	print("KEYBOARD_MENU_REPEAT_RESULT checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
