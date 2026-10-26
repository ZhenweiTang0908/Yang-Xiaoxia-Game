extends SceneTree
var failures=[]
var checks=0
var captures=[]
func capture(hud):
	if not "--visual" in OS.get_cmdline_user_args():return
	hud.canvas.queue_redraw()
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	var image=root.get_texture().get_image()
	var scale_factor=image.get_width()/960.0
	var region=Rect2i(int(290*scale_factor),int(115*scale_factor),int(380*scale_factor),int(50*scale_factor))
	captures.append(image.get_region(region))
func _initialize():call_deferred("run")
func verify(ok,label):
	checks+=1
	if not ok:failures.append(label);push_error(label)
func run():
	root.unfocusable=true
	var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true
	await process_frame;await process_frame
	game.start_new(false);await process_frame
	game.process_mode=Node.PROCESS_MODE_DISABLED
	game.state="playing";game.hitstop=0
	var hud=game.hud;var boss=game.boss
	verify(is_instance_valid(boss),"boss exists")
	if not is_instance_valid(boss):game.queue_free();quit(1);return
	boss.active_battle=true
	boss.hp=boss.max_hp;hud._process(.01)
	await capture(hud)
	boss.hp=boss.max_hp*.8;hud._process(.01)
	await capture(hud)
	verify(is_equal_approx(hud.boss_lag,1.0),"first hit leaves a visible damage band")
	hud._process(.5)
	await capture(hud)
	verify(hud.boss_lag<1.0 and hud.boss_lag>=.8,"damage band drains toward current health")
	var trailing=hud.boss_lag
	boss.hp=boss.max_hp*.6;hud._process(.01)
	await capture(hud)
	verify(is_equal_approx(hud.boss_lag,trailing) and hud.boss_lag_hold>.4,"another hit renews the damage hold")
	var hold=hud.boss_lag_hold
	game.state="paused";hud._process(.2)
	verify(is_equal_approx(hud.boss_lag_hold,hold),"pause freezes damage feedback")
	game.state="playing";game.hitstop=.1;hud._process(.2)
	verify(is_equal_approx(hud.boss_lag_hold,hold),"hitstop freezes damage feedback")
	game.hitstop=0;hud._process(.5);hud._process(1)
	await capture(hud)
	verify(is_equal_approx(hud.boss_lag,.6),"damage band settles at current health")
	hud.boss_lag_owner=0;boss.hp=boss.max_hp*.9;hud._process(.01)
	verify(is_equal_approx(hud.boss_lag,.9),"new boss discards old damage feedback")
	if not captures.is_empty():
		var size=captures[0].get_size()
		var sheet=Image.create(size.x,size.y*captures.size(),false,Image.FORMAT_RGBA8)
		for i in captures.size():sheet.blit_rect(captures[i],Rect2i(Vector2i.ZERO,size),Vector2i(0,i*size.y))
		verify(sheet.save_png("/private/tmp/yang-boss-health-feedback.png")==OK,"visual sequence saved")
	game.queue_free();await process_frame
	print("BOSS_HEALTH_FEEDBACK_RESULT checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
