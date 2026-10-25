extends SceneTree
var failures=[]
var checks=0
var game

func _initialize():call_deferred("run")
func verify(condition,label):
	checks+=1
	if condition:print("PASS ",label)
	else:failures.append(label);push_error("FAIL "+label)
func feature_node():
	for child in game.terrain.get_children():
		if child.get_script() and child.get_script().resource_path.ends_with("room_features.gd"):return child
	return null
func redraw():
	game.hud.canvas.queue_redraw();await process_frame;await process_frame
func actions():return game.hud.buttons.map(func(button):return button.action)
func run():
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.developer_mode=false
	game.start_new(false);await process_frame
	var fallback=game.death_guide("not_a_real_source")
	verify(fallback.title=="力尽倒下" and not fallback.tip.is_empty(),"unknown damage source has an honest fallback")
	var expected={"fall":"失足坠落","spikes":"庭院地刺","ritual":"幽钟祭阵","sweep":"近身横扫","dart":"飞刃命中","ghost_orb":"追魂灵弹","ground_rift":"地脉裂隙","spirit_lightning":"引魂雷击","rain":"幽光落雨","spirit_beam":"幽焰长息"}
	verify(expected.keys().all(func(source):return game.death_guide(source).title==expected[source] and not game.death_guide(source).tip.is_empty()),"authored combat families expose distinct causes and advice")
	var p=game.player;p.health=100;p.invincible=0;p.take_damage(12,0,"dart")
	verify(game.state=="playing" and game.death_source.is_empty(),"nonfatal damage does not pollute the death report")

	p.health=1;p.invincible=0;game.hitstop=0
	game.combat.fire(p.position-Vector2(0,21),Vector2.RIGHT,20,"enemy","dart")
	game.combat._physics_process(.01)
	verify(game.state=="dead" and game.death_source=="dart","real enemy projectile records its fatal source")
	await redraw()
	verify(actions()==["retry","settings","stage_select","title"],"death report preserves retry and exposes free stage navigation")
	game.hud.pad_activate();await process_frame;await process_frame
	verify(game.state=="playing" and game.death_source.is_empty(),"controller retry clears the previous death report")

	p=game.player;p.health=1;p.invincible=0;game.hitstop=0
	game.combat.hazard(Rect2(p.position-Vector2(20,48),Vector2(40,52)),0,.2,100,1,"spirit_lightning")
	game.combat._physics_process(.01)
	verify(game.state=="dead" and game.death_source=="spirit_lightning","real combat hazard records its fatal source")

	game.load_stage(1,0);await process_frame;p=game.player
	var features=feature_node();var spike=features.items.filter(func(item):return item.kind=="spikes")[0]
	p.position=Vector2(spike.x+spike.w*.5,spike.y);p.health=1;p.invincible=0;features.clock=spike.period-.5;features._physics_process(.01)
	verify(game.state=="dead" and game.death_source=="spikes","authored stage spikes report their own cause")

	game.load_stage(3,0);await process_frame;p=game.player;features=feature_node()
	var ritual=features.items.filter(func(item):return item.kind=="ritual")[0]
	p.position=Vector2(ritual.x,ritual.y);p.health=1;p.invincible=0;features.clock=ritual.period-ritual.get("phase",0.0)-.2;features._physics_process(.01)
	verify(game.state=="dead" and game.death_source=="ritual","authored ritual field reports its own cause")

	game.load_stage(1,0);await process_frame;p=game.player;p.health=1;p.invincible=0;game.fall_recover()
	verify(game.state=="dead" and game.death_source=="fall","fatal fall recovery reports a fall instead of a generic hit")
	game.audio.stop_all();game.queue_free();await process_frame;await process_frame;await create_timer(.2).timeout;OS.delay_msec(100)
	print("DEATH_GUIDE_RESULT checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
