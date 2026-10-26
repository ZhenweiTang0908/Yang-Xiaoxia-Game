extends SceneTree
var failures=[]
var checks=0
func _initialize():call_deferred("run")
func verify(ok,label):
	checks+=1
	if not ok:failures.append(label);push_error(label)
func touch(game,index,pressed,at,device=0):
	var event=InputEventScreenTouch.new();event.index=index;event.pressed=pressed;event.position=at
	event.device=device
	game._input(event)
func mouse_click(game,at,device=0):
	var event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=true;event.position=at
	event.device=device;game._input(event)
func run():
	var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true
	await process_frame;await process_frame
	game.start_new(false);await process_frame
	game.process_mode=Node.PROCESS_MODE_DISABLED;game.is_touch=true
	var layout=game.hud.touch_layout();var jump=layout.filter(func(button):return button.action=="jump")[0].rect.get_center()
	var controls_fit=true
	for i in layout.size():
		controls_fit=controls_fit and Rect2(0,0,960,540).encloses(layout[i].rect)
		for j in range(i+1,layout.size()):controls_fit=controls_fit and not layout[i].rect.intersects(layout[j].rect)
	verify(controls_fit,"touch controls fit the canvas without overlap")
	touch(game,1,true,jump);touch(game,2,true,jump)
	verify(Input.is_action_pressed("jump"),"two touches hold the shared action")
	touch(game,1,false,jump)
	verify(Input.is_action_pressed("jump") and game.touch_ids.size()==1,"first release leaves the other touch active")
	touch(game,2,false,jump)
	verify(not Input.is_action_pressed("jump") and game.touch_ids.is_empty(),"last release ends the shared action")
	verify(game.player.edges.get("jump_release",false),"jump release edge fires only after the last finger lifts")
	game.state="settings";game.hud.canvas.queue_redraw();await process_frame;await process_frame
	var volume=game.hud.buttons.filter(func(entry):return entry.action=="volume_music_1")[0].rect.get_center()
	var before=float(game.progress.music)
	touch(game,3,true,volume);mouse_click(game,volume,InputEvent.DEVICE_ID_EMULATION)
	verify(is_equal_approx(game.progress.music,before+.1),"emulated mouse does not double a physical touch click")
	before=float(game.progress.music)
	mouse_click(game,volume);touch(game,4,true,volume,InputEvent.DEVICE_ID_EMULATION)
	verify(is_equal_approx(game.progress.music,before+.1),"emulated touch does not double a physical mouse click")
	game.release_inputs();game.queue_free();await process_frame
	print("TOUCH_MULTITOUCH_RESULT checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
