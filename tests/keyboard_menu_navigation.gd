extends SceneTree
var failures=[]
var checks=0
var game
func _initialize():call_deferred("run")
func verify(ok,label):
	checks+=1
	if not ok:failures.append(label);push_error(label)
func key(code):
	var event=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=true;game._input(event)
func run():
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game)
	await process_frame;await process_frame
	game.qa_mode=true;game.progress=game.SAVE.defaults();game.state="title";game.hud.canvas.queue_redraw()
	await process_frame;await process_frame
	var stage_index=game.hud.buttons.find_custom(func(entry):return entry.action=="stage_select")
	key(KEY_DOWN)
	verify(game.keyboard_nav and not game.pad_mode and game.hud.pad_focus==stage_index,"keyboard down focuses the next title row")
	key(KEY_RIGHT)
	verify(game.hud.buttons[game.hud.pad_focus].action=="settings","keyboard right follows the nearest title control")
	key(KEY_ENTER)
	verify(game.state=="settings" and game.hud.settings_return=="title","Enter activates the focused settings action")
	await process_frame;await process_frame
	verify(game.hud.pad_state=="settings" and game.hud.pad_focus==0,"settings starts with a valid keyboard focus")
	var music=game.progress.music
	key(KEY_SPACE)
	verify(is_equal_approx(game.progress.music,music-.1),"Space activates the focused setting")
	var pad=InputEventJoypadButton.new();pad.device=0;pad.button_index=JOY_BUTTON_DPAD_RIGHT;pad.pressed=true;game._input(pad)
	verify(game.pad_mode and not game.keyboard_nav,"gamepad input replaces keyboard focus mode")
	await process_frame;await process_frame
	var back_index=game.hud.buttons.find_custom(func(entry):return entry.action=="back")
	var motion=InputEventMouseMotion.new();motion.position=game.hud.buttons[back_index].rect.get_center();game._input(motion)
	verify(not game.pad_mode and not game.keyboard_nav,"mouse movement leaves gamepad focus mode")
	var mouse=InputEventMouseButton.new();mouse.button_index=MOUSE_BUTTON_LEFT;mouse.pressed=true;mouse.position=game.hud.buttons[back_index].rect.get_center();game._input(mouse)
	verify(game.state=="title" and not game.keyboard_nav,"mouse click returns to title and clears keyboard focus mode")
	key(KEY_DOWN);verify(game.keyboard_nav,"keyboard navigation remains active until pointer movement")
	game._input(motion)
	verify(not game.keyboard_nav,"mouse movement restores pointer hover after keyboard navigation")
	game.audio.stop_all();game.queue_free();await process_frame;await process_frame
	print("KEYBOARD_MENU_NAVIGATION_RESULT checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
