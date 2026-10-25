extends SceneTree
var failures=[]
func _initialize():call_deferred("run")
func verify(ok,label):
	if ok:print("PASS ",label)
	else:failures.append(label);push_error(label)
func run():
	var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.progress=game.SAVE.defaults();game.start_new(false)
	game.set_process(false);game.set_physics_process(false);game.player.set_physics_process(false)
	for enemy in game.enemies:enemy.dead=true;enemy.set_physics_process(false)
	await process_frame
	var p=game.player;var motion=p.skeletal_visual.painted_motion;motion.set_physics_process(false)
	var rig=motion.rig
	for index in 3:
		game.state="playing";game.hitstop=0;p.combo=index+1;p.attack_elapsed=p.MOTION.ATTACKS[index].hit-.03
		p.hurt_anim=0;p.dash_time=0;p.charge=0;p.blast_anim=0;p.bow_anim=0
		motion._physics_process(.12)
		var anticipation_tip=rig.sampled_pose[7]*Vector2(120,168)
		p.attack_elapsed=p.MOTION.ATTACKS[index].hit;game.hitstop=.035
		motion._physics_process(.016)
		var impact_tip=rig.sampled_pose[7]*Vector2(120,168)
		verify(is_equal_approx(rig.attack_elapsed,p.attack_elapsed) and impact_tip.distance_to(anticipation_tip)>5,"impact pose appears during hitstop for slash "+str(index+1))
		var frozen=rig.blade_history.duplicate(true);var pose=rig.sampled_pose.duplicate()
		motion._physics_process(.016);motion._physics_process(.016)
		verify(rig.blade_history==frozen and rig.sampled_pose==pose,"hitstop freezes pose and ribbon for slash "+str(index+1))
		game.state="paused";p.attack_elapsed+=.02;motion._physics_process(.016)
		verify(rig.sampled_pose==pose,"pause freezes attack pose for slash "+str(index+1))
	game.audio.stop_all();game.queue_free();await process_frame;await process_frame;await create_timer(.2).timeout
	print("ATTACK_READABILITY_RESULT failures=",failures)
	quit(0 if failures.is_empty() else 1)
