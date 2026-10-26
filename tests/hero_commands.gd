extends SceneTree
const COMMAND=preload("res://scripts/combat/command_input.gd")
var failures=[]
var checks=0
var game
func _initialize():call_deferred("run")
func verify(ok,label):
	checks+=1
	if ok:print("PASS ",label)
	else:failures.append(label);push_error(label)
func sequence(steps,face=1):
	var input=COMMAND.new()
	for direction in steps:input.sample(direction,face);input.tick(.08)
	return input.take()
func direction(p,x,down):
	for action in ["left","right","down"]:Input.action_release(action)
	if x!=0:Input.action_press("right" if x>0 else "left")
	if down:Input.action_press("down")
	p._physics_process(.04)
func prepare(p):
	game.release_inputs();game.state="playing";game.hitstop=0;game.combat.clear();game.fx.clear()
	p.reset(Vector2(500,450),true);p.facing=1;p.invincible=0;p.bow_anim=0;p.form_transition=0
	for e in game.enemies:e.dead=true
func run():
	for face in [1,-1]:
		verify(sequence([Vector2.DOWN,Vector2(face,0)],face).get("id")=="wave","mirrored wave "+str(face))
		var spin=sequence([Vector2.DOWN,Vector2(-face,1),Vector2(-face,0)],face)
		verify(spin.get("id")=="spin" and spin.face==face,"mirrored spin keeps starting facing "+str(face))
		verify(sequence([Vector2(face,0),Vector2.DOWN,Vector2(face,1),Vector2(face,0)],face).get("id")=="rising","rising wins over wave suffix "+str(face))
	verify(sequence([Vector2.DOWN,Vector2(1,1)]).get("id")=="wave","diagonal finish accepted")
	verify(sequence([Vector2.RIGHT]).is_empty(),"one direction is not a command")
	verify(sequence([Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]).is_empty(),"wrong order rejected")
	var input=COMMAND.new();input.sample(Vector2.DOWN,1);input.tick(.76);input.sample(Vector2.RIGHT,1)
	verify(input.take().is_empty(),"expired first direction rejected")
	input.clear();input.sample(Vector2.DOWN,1);input.sample(Vector2.RIGHT,1);input.tick(.31)
	verify(input.take().is_empty(),"late attack rejected")
	input.clear();input.sample(Vector2.DOWN,1);input.sample(Vector2.RIGHT,1)
	verify(not input.take().is_empty() and input.take().is_empty(),"command can be consumed only once")
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.start_new(false)
	game.set_process(false);game.set_physics_process(false)
	for enemy in game.enemies:enemy.set_physics_process(false)
	game.player.set_physics_process(false);game.combat.set_physics_process(false)
	await process_frame
	var p=game.player
	for id in ["wave","spin","rising"]:
		prepare(p)
		if id=="rising":direction(p,1,false)
		direction(p,0,true);direction(p,-1 if id=="spin" else 1,false)
		p.enqueue("attack");p._physics_process(.01)
		verify(p.special_id==id,"real input starts "+id)
		verify(not p.attack_hit and game.combat.shots.is_empty(),"anticipation before "+id)
		var target=game.enemies[0];target.dead=false;target.hp=500;target.position=p.position+Vector2(-50 if id=="spin" else 40,0)
		var hp=target.hp
		game.hitstop=0;p._physics_process(.23)
		verify(p.attack_hit,"impact reached for "+id)
		if id=="wave":
			verify(target.hp==hp and game.combat.shots.size()==1 and game.combat.shots[0].pierce==2,"wave emits one piercing projectile instead of instant melee")
			game.combat._physics_process(.08)
			verify(target.hp<hp,"wave projectile damages target")
		else:verify(target.hp<hp,"special damages "+("rear target" if id=="spin" else "front target"))
		if id=="rising":verify(p.velocity.y<0,"rising launches player upward")
		game.hitstop=0;var after=target.hp;p._physics_process(.01)
		verify(target.hp==after,"no repeated melee damage for "+id)
	prepare(p);p.special_cd=.8;direction(p,0,true);direction(p,1,false);p.enqueue("attack");p._physics_process(.01)
	verify(p.special_id=="" and p.attack_elapsed>=0 and p.pending_command.is_empty(),"cooldown falls back to ordinary attack")
	prepare(p);direction(p,0,true);direction(p,1,false);game.state="paused";game.release_inputs();game.state="playing";p.enqueue("attack");p._physics_process(.01)
	verify(p.special_id=="","pause clears unfinished motion")
	prepare(p);p.sheep_time=10;direction(p,0,true);direction(p,1,false);p.enqueue("attack");p._physics_process(.01)
	verify(p.special_id=="" and p.attack_elapsed>=0,"sheep form retains ordinary attacks")
	prepare(p);direction(p,0,true);direction(p,1,false);p.start_attack();p.attack_elapsed=.05;p.enqueue("attack");p._physics_process(.01)
	verify(p.special_id=="" and not p.pending_command.is_empty(),"command buffers through normal anticipation")
	game.hitstop=0;p._physics_process(.1);game.hitstop=0;p._physics_process(.01)
	verify(p.special_id=="wave","command cancels ordinary recovery after impact")
	prepare(p);direction(p,0,true);direction(p,1,false);game.hitstop=.04;p.enqueue("attack");p._physics_process(.01);game.hitstop=0;p._physics_process(.01)
	verify(p.special_id=="wave","command survives hitstop input buffering")
	prepare(p);direction(p,0,true);direction(p,1,false);p.take_damage(1,-1);p.enqueue("attack");p._physics_process(.01)
	verify(p.special_id=="","taking damage clears motion history")
	prepare(p);var boss=game.boss;boss.dead=false;boss.active_battle=false;boss.position=p.position+Vector2(40,0);var hp=boss.hp
	game.combat.command_attack(p,"spin")
	verify(boss.hp==hp,"inactive boss is protected")
	game.release_inputs();game.audio.stop_all();game.queue_free();await process_frame;await process_frame;await create_timer(.2).timeout
	print("HERO_COMMANDS_RESULT checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
