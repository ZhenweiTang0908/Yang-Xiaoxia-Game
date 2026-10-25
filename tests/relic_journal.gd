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
func key_escape():
	var event=InputEventKey.new();event.pressed=true;event.physical_keycode=KEY_ESCAPE;game._input(event)
func gamepad_back():
	game.gamepad.glyphs="switch"
	var event=InputEventJoypadButton.new();event.pressed=true;event.button_index=JOY_BUTTON_A;game.gamepad.handle(event)
func run():
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.developer_mode=false
	await redraw()
	game.progress.relics=[];await redraw()
	verify(not actions().has("relic_journal"),"title hides the moon journal until a relic is found")
	game.progress.relics=["moon_1_roof","moon_2_seal"];await redraw()
	verify(actions().has("relic_journal"),"release title exposes the moon journal")
	game.hud.action("relic_journal");await redraw()
	verify(game.state=="relic_journal" and game.hud.relic_journal_return=="title","title opens journal with a title return path")
	var rows=game.hud.relic_journal_rows()
	verify(rows.size()==6 and rows.filter(func(row):return row.collected).size()==2,"journal distinguishes collected and missing entries")
	verify(rows[0].name=="初照" and "并肩出发" in rows[0].body,"collected entry exposes its complete lore")
	verify(actions()==["relic_journal_back"],"journal has a single unambiguous navigation action")
	game.hud.pad_activate();verify(game.state=="title","controller confirm activates journal back")

	game.start_new(false);game.state="paused";var elapsed=game.elapsed;await redraw()
	verify(actions().has("relic_journal"),"pause overlay exposes the moon journal")
	game.hud.action("relic_journal")
	for i in 30:await process_frame
	verify(is_equal_approx(game.elapsed,elapsed),"journal keeps gameplay time frozen")
	key_escape();verify(game.state=="paused","keyboard escape returns to the pause source")
	game.hud.action("relic_journal");gamepad_back();verify(game.state=="paused","controller back returns to the pause source")
	game.audio.stop_all();game.queue_free();await process_frame;await process_frame;await create_timer(.2).timeout;OS.delay_msec(100)
	print("RELIC_JOURNAL_RESULT checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
