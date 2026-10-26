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
	game.state="title";game.pad_mode=true
	await process_frame;await process_frame
	var hud=game.hud
	var index=hud.buttons.find_custom(func(b):return b.action=="settings")
	verify(index>=0,"title settings button exists")
	if index<0:game.queue_free();quit(1);return
	hud.pad_focus=index;hud.pad_activate()
	verify(game.state=="settings" and hud.settings_return=="title","first confirmation opens settings")
	hud.pad_activate()
	verify(hud.settings_return=="title","repeat confirmation cannot activate previous page settings button")
	hud.pad_move(Vector2.DOWN)
	verify(hud.pad_focus==index,"navigation waits for the new page button list")
	verify(not hud.handle_click(hud.buttons[0].rect.get_center()) and game.state=="settings","click cannot activate a previous page button")
	await process_frame;await process_frame
	verify(hud.pad_state=="settings" and hud.pad_focus==0,"new page paints its own initial focus")
	hud.action("back")
	verify(game.state=="title","back still returns to the original page")
	game.queue_free();await process_frame
	print("MENU_TRANSITION_INPUT_RESULT checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
