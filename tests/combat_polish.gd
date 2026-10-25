extends SceneTree
var failures=[]
var checks=0
func _initialize():call_deferred("run")
func verify(ok,label):
	checks+=1
	if ok:print("PASS ",label)
	else:failures.append(label);push_error(label)
func run():
	var rig=load("res://scripts/animation/painted_rig/combo.gd").new();root.add_child(rig);rig.set_process(false)
	for id in ["wave","spin","rising"]:
		var index={"wave":0,"spin":1,"rising":2}[id];var move=rig.MOTION.ATTACKS[index]
		rig.sample_attack(index,move.hit+.035,1.0/60)
		var normal=rig.sampled_pose[7]*Vector2(120,168)
		rig.sample_attack(index,move.hit+.035,1.0/60,id)
		verify(normal.distance_to(rig.sampled_pose[7]*Vector2(120,168))>5,id+" has a distinct weapon pose")
		var error=0.0
		for i in 61:
			rig.sample_attack(index,move.duration*i/60.0,1.0/60,id)
			var pose=rig.sampled_pose
			error=maxf(error,(pose[9]*Vector2(64,125)).distance_to(pose[7]*Vector2(64,125)))
			error=maxf(error,absf((pose[7]*Vector2(74,149)).distance_to(pose[7]*Vector2(120,168))-Vector2(46,19).length()))
		verify(error<.001,id+" keeps elbow and sword rigid through the full motion")
	rig.queue_free()
	var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.progress=game.SAVE.defaults();game.start_new(false)
	game.set_process(false);game.set_physics_process(false);game.player.set_physics_process(false)
	for enemy in game.enemies:enemy.dead=true;enemy.set_physics_process(false)
	var p=game.player;var fx=game.fx;game.state="playing";game.hitstop=0
	var motion=p.skeletal_visual.painted_motion;motion.set_physics_process(false)
	p.combo=1;p.attack_elapsed=.16;motion._physics_process(.016)
	p.special_id="wave";p.attack_elapsed=.02;motion._physics_process(.016)
	verify(motion.last_command=="wave" and motion.rig.command_id=="wave" and motion.rig.blade_history.is_empty(),"same-slot command transition clears old sword trail")
	for id in ["wave","spin","rising"]:
		fx.clear();game.combat.command_attack(p,id)
		verify(fx.command_effects.size()==1 and fx.command_effects[0].id==id,id+" emits one matching effect at the damage event")
	game.state="paused";fx._process(.2)
	verify(fx.command_effects[0].age==0,"pause freezes command effects")
	game.state="playing";game.hitstop=.1;fx._process(.2)
	verify(fx.command_effects[0].age==0,"hitstop freezes command effects")
	game.hitstop=0;fx._process(.61)
	verify(fx.command_effects.is_empty(),"command effects expire after their short release")
	for i in 20:fx.command_effect(Vector2.ZERO,"spin",-1)
	verify(fx.command_effects.size()==6,"command effect count stays bounded")
	fx.clear();verify(fx.command_effects.is_empty(),"clear removes all command effects")
	p.position=Vector2(500,450);p.facing=1;p.combo=1;game.shake=0;game.combat.melee(p)
	verify(game.shake==0 and fx.melee_contacts.is_empty() and fx.hit_marks.is_empty(),"whiff creates no contact or camera shake")
	var enemy=game.enemies[0];enemy.dead=false;enemy.kind="shield";enemy.facing=-1;enemy.hp=1000;enemy.position=p.position+Vector2(30,0)
	game.combat.melee(p)
	verify(fx.hit_marks.size()==1 and fx.hit_marks[0].style=="block" and fx.melee_contacts[0].surface=="block","frontal shield hit uses shield feedback")
	var light=game.shake;game.hitstop=0;game.shake=0;p.combo=3;enemy.kind="imp";game.combat.melee(p)
	verify(game.shake>light,"finisher hit carries more camera weight than a blocked light slash")
	game.progress.screen_shake=false;game._process(.016)
	verify(game.camera.offset==Vector2.ZERO,"disabled camera shake remains disabled")
	game.audio.stop_all();game.queue_free();await process_frame;await process_frame;await create_timer(.2).timeout
	print("COMBAT_POLISH_RESULT checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
