extends SceneTree
var failures=[]
var checks=0
var game

func _initialize():call_deferred("run")
func verify(condition,label):
	checks+=1
	if condition:print("PASS ",label)
	else:failures.append(label);push_error("FAIL "+label)
func run():
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.start_new(false);await process_frame
	var boss=game.boss;boss.active_battle=true;boss.cooldown=10;boss.windup=.5;boss.strike=.3;boss.events=[{"delay":.4,"type":"close_slash","payload":{"damage":12},"done":false}];boss.dash_left=.2;boss.leap_left=.2
	var owner=boss.get_instance_id();game.combat.fire(boss.position,Vector2.RIGHT,10,"enemy","blade",{"owner":owner});game.combat.hazard(Rect2(1,1,2,2),0,.2,10,owner,"sweep");game.combat.hazard(Rect2(5,5,2,2),0,.2,10,999,"sweep")
	boss.hp=boss.max_hp*.49;boss._physics_process(.01)
	verify(boss.phase==2 and boss.phase_shift>1.2 and boss.phase_title()=="灯火暴走","lantern threshold starts its named second phase")
	verify(boss.windup==0 and boss.strike==0 and boss.events.is_empty() and boss.dash_left==0 and boss.leap_left==0,"phase shift cancels pending attacks and movement")
	verify(game.combat.shots.all(func(shot):return shot.owner!=owner) and game.combat.hazards.all(func(hazard):return hazard.owner!=owner),"phase shift removes every boss-owned attack")
	verify(game.combat.hazards.any(func(hazard):return hazard.owner==999),"phase shift preserves unrelated combat effects")
	var hp=boss.hp;boss.take_hit(100,"player",1)
	verify(boss.hp==hp,"boss cannot be damaged during the visible transition")
	var frozen=boss.phase_shift;game.state="paused";boss._physics_process(.5)
	verify(is_equal_approx(boss.phase_shift,frozen),"pause freezes the phase transition")
	game.state="playing";boss._physics_process(1.3)
	verify(boss.phase_shift==0 and is_equal_approx(boss.cooldown,.65),"transition ends with an authored recovery window")
	for i in 40:boss._physics_process(.02)
	verify(boss.windup>0 and not boss.move.is_empty(),"boss resumes its move cycle after recovery")

	game.load_stage(2,0);await process_frame;boss=game.boss;boss.active_battle=true;boss.cooldown=10;boss.hp=boss.max_hp*.49;boss._physics_process(.01)
	verify(boss.phase==2 and boss.phase_title()=="影刃加速","duelist threshold starts its named second phase")
	game.load_stage(3,0);await process_frame;boss=game.boss;boss.active_battle=true;boss.cooldown=10;boss.hp=boss.max_hp*.64;boss._physics_process(.01)
	verify(boss.phase==2 and boss.phase_title()=="月蚀初临","priest first threshold starts the second phase")
	boss.phase_shift=0;boss.hp=boss.max_hp*.29;boss._physics_process(.01)
	verify(boss.phase==3 and boss.phase_title()=="噬月终仪","priest final threshold starts the third phase")
	game.audio.stop_all();game.queue_free();await process_frame;await process_frame;await create_timer(.2).timeout;OS.delay_msec(100)
	print("BOSS_PHASE_SHIFT_RESULT checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
